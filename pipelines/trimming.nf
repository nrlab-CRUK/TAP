/*
 * Trimming processes.
 */

include { javaMemMB } from '../processes/picard'

def baseName(fastqFile)
{
    def name = fastqFile.name
    name = name.replaceAll(/\.(fq|fastq)(\.gz)?$/, "")
    name = name.replaceAll(/\.r_\d$/, "")
    return name
}

process trimGalore
{
    cpus   16
    memory 1.GB
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1), path(read2), val(hasUmiRead), path(umiread)

    output:
        tuple val(sampleId), path("${fileBase}_val_1.fq.gz"), path("${fileBase}_val_2.fq.gz"), val(hasUmiRead), path(umiread)

    shell:
        fileBase = baseName(read1)

        template "trimming/trimGalore.sh"
}

process tagtrim
{
    memory { 256.MB * task.attempt }
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1In), path(read2In)

    output:
        tuple val(sampleId), path(read1Out), path(read2Out), path(umi1Out), path(umi2Out)

    shell:
        fileBase = baseName(read1In)
        read1Out = "${fileBase}.r_1.tagtrim.fq.gz"
        read2Out = "${fileBase}.r_2.tagtrim.fq.gz"
        umi1Out = "${fileBase}.u_1.tagtrim.fq.gz"
        umi2Out = "${fileBase}.u_2.tagtrim.fq.gz"

        template "trimming/tagtrim.sh"
}

process agentTrimmer
{
    cpus   4
    memory { 4.GB * task.attempt }
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1In), path(read2In)

    output:
        tuple val(sampleId), path(read1Out), path(read2Out)

    shell:
        javaMem = javaMemMB(task)
        read1Out = "${sampleId}_R1.fastq.gz"
        read2Out = "${sampleId}_R2.fastq.gz"

        template "trimming/agentTrimmer.sh"
}

process prependXTHS2UMI {
    memory { 1.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1), path(read2)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        python3 "${projectDir}/python/prepend_xths2_umi.py" \
            "!{read1}" "!{read2}" "!{read1out}" "!{read2out}"
        """
}

process prependSingleUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    memory { 1.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umiread}" "!{read1}" "!{read1out}"
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umiread}" "!{read2}" "!{read2out}"
        """
}

process prependDoubleUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    memory { 1.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(sampleId), path(read1), path(read2), path(umi1), path(umi2)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umi1}" "!{read1}" "!{read1out}"
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umi2}" "!{read2}" "!{read2out}"
        """
}


workflow trimGaloreWF
{
    take:
        fastqChannel

    main:
        trimmed = trimGalore(fastqChannel.map { s, r1, r2, hU, rU, info -> tuple s, r1, r2, hU, rU })

        // only prepend UMI read if one was specified in the UmiRead column in
        // the sample sheet AND Connor UMI-based deduplication is requested

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING && it[3]
            noConnor : true
        }

        prependSingleUMI(prepended.connor.map { s, r1, r2, hU, rU -> tuple s, r1, r2, rU })

        noConnorChannel = prepended.noConnor.map { s, r1, r2, hU, rU -> tuple s, r1, r2 }

        trimmedChannel = noConnorChannel.mix(prependSingleUMI.out)

    emit:
        trimmedChannel
}

workflow tagtrimWF
{
    take:
        fastqChannel

    main:
        trimmed = tagtrim(fastqChannel.map { s, r1, r2, hU, rU, info -> tuple s, r1, r2 })

        // only prepend the extracted UMI reads from tagtrim if Connor
        // deduplication is requested

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        prependDoubleUMI(prepended.connor)

        noConnorChannel = prepended.noConnor.map { s, r1, r2, u1, u2 -> tuple s, r1, r2 }

        trimmedChannel = noConnorChannel.mix(prependDoubleUMI.out)

    emit:
        trimmedChannel
}

workflow agentTrimmerWF
{
    take:
        fastqChannel

    main:
        trimmed = agentTrimmer(fastqChannel.map { s, r1, r2, hU, rU, info -> tuple s, r1, r2 })

        // only prepend the extracted UMT from AGeNT trimmer if Connor
        // deduplication is requested

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        // TODO need to replace this with a new, bespoke utility for pre-pending
        // the UMT bases from the read header; also need to update to use a more
        // recent version of the AGeNT trimmer
        prependXTHS2UMI(prepended.connor)

        trimmedChannel = prepended.noConnor.mix(prependXTHS2UMI.out)

    emit:
        trimmedChannel
}

workflow noTrimWF
{
    take:
        fastqChannel

    main:
        // only prepend UMI read if one was specified in the UmiRead column in
        // the sample sheet AND Connor UMI-based deduplication is requested

        prepended = fastqChannel.branch
        {
            connor : params.CONNOR_COLLAPSING && it[3]
            noConnor : true
        }

        prependSingleUMI(prepended.connor.map { s, r1, r2, hU, rU, info -> tuple s, r1, r2, rU })

        noConnorChannel = prepended.noConnor.map { s, r1, r2, hU, rU, info -> tuple s, r1, r2 }

        trimmedChannel = noConnorChannel.mix(prependSingleUMI.out)

    emit:
        trimmedChannel
}

workflow trimming
{
    take:
        fastqChannel
        sampleInfoChannel

    main:
        withSampleInfoChannel = fastqChannel.combine(sampleInfoChannel, by: 0)

        trimOut = withSampleInfoChannel.branch
        {
            tagtrim : it[5]['Index Type'] == 'ThruPLEX DNA-seq Dualindex'
            agentTrimmer : it[5]['Index Type'] == 'SureSelectXT HS2'
            trimGalore : params.TRIM_FASTQ
            noTrim : true
        }

        trimGaloreWF(trimOut.trimGalore)
        tagtrimWF(trimOut.tagtrim)
        agentTrimmerWF(trimOut.agentTrimmer)
        noTrimWF(trimOut.noTrim)

        afterTrimmingChannel = noTrimWF.out.mix(trimGaloreWF.out).mix(tagtrimWF.out).mix(agentTrimmerWF.out)

    emit:
        afterTrimmingChannel
}
