/*
 * Trimming processes.
 */

include { javaMemMB; safeName } from "../modules/nextflow-support/functions"

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
        tuple val(unitId), val(chunk), path(read1In), path(read2In), val(hasUmiRead), path(umiread)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out), val(hasUmiRead), path(umiread)

    shell:
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}_val_1.fq.gz"
        read2Out = "${outFilePrefix}_val_2.fq.gz"

        template "trimming/trimGalore.sh"
}

process tagtrim
{
    memory { 256.MB * task.attempt }
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out), path(umi1Out), path(umi2Out)

    shell:
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}.r_1.tagtrim.fq.gz"
        read2Out = "${outFilePrefix}.r_2.tagtrim.fq.gz"
        umi1Out = "${outFilePrefix}.u_1.tagtrim.fq.gz"
        umi2Out = "${outFilePrefix}.u_2.tagtrim.fq.gz"

        template "trimming/tagtrim.sh"
}

process agentTrimmer
{
    cpus   4
    memory { 4.GB * task.attempt }
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        javaMem = javaMemMB(task)
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}_R1.fastq.gz"
        read2Out = "${outFilePrefix}_R2.fastq.gz"
        umiOut = "${outFilePrefix}_MBC.txt.gz"

        template "trimming/agentTrimmer.sh"
}

process prependXTHS2UMI
{
    memory { 1.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        safeUnitId = safeName(unitId)
        read1Out = "${safeUnitId}.umi.r_1.c_${chunk}.fq.gz"
        read2Out = "${safeUnitId}.umi.r_2.c_${chunk}.fq.gz"

        """
        python3 "${projectDir}/python/prepend_xths2_umi.py" \
            "!{read1In}" "!{read2In}" "!{read1Out}" "!{read2Out}"
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
        tuple val(unitId), val(chunk), path(read1In), path(read2In), path(umiread)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        safeUnitId = safeName(unitId)
        read1Out = "${safeUnitId}.umi.r_1.c_${chunk}.fq.gz"
        read2Out = "${safeUnitId}.umi.r_2.c_${chunk}.fq.gz"

        """
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umiread}" "!{read1In}" "!{read1Out}"
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umiread}" "!{read2In}" "!{read2Out}"
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
        tuple val(unitId), val(chunk), path(read1In), path(read2In), path(umi1), path(umi2)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        safeUnitId = safeName(unitId)
        read1Out = "${safeUnitId}.umi.r_1.c_${chunk}.fq.gz"
        read2Out = "${safeUnitId}.umi.r_2.c_${chunk}.fq.gz"

        """
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umi1}" "!{read1In}" "!{read1Out}"
        python3 "${projectDir}/python/concat_fastq.py" \
            "!{umi2}" "!{read2In}" "!{read2Out}"
        """
}


workflow trimGaloreWF
{
    take:
        fastqChannel

    main:
        trimmed = trimGalore(
            fastqChannel
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU, info ->
                tuple unitId, chunk, read1, read2, hasUmi, readU
            })

        // only prepend UMI read if one was specified in the UmiRead column in
        // the sample sheet AND Connor UMI-based deduplication is requested

        prepended = trimmed.branch
        {
            unitId, chunk, read1, read2, hasUMI, readU ->
            connor : params.CONNOR_COLLAPSING && hasUMI
            noConnor : true
        }

        prependSingleUMI(
            prepended.connor
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU ->
                tuple unitId, chunk, read1, read2, readU
            })

        noConnorChannel = prepended.noConnor
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU ->
                tuple unitId, chunk, read1, read2
            }

        trimmedChannel = noConnorChannel.mix(prependSingleUMI.out)

    emit:
        trimmedChannel
}

workflow tagtrimWF
{
    take:
        fastqChannel

    main:
        trimmed = tagtrim(
            fastqChannel
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU, info ->
                tuple unitId, chunk, read1, read2
            })

        // only prepend the extracted UMI reads from tagtrim if Connor
        // deduplication is requested

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        prependDoubleUMI(prepended.connor)

        noConnorChannel =
            prepended.noConnor
            .map
            {
                unitId, chunk, read1, read2, umi1, umi2 ->
                tuple unitId, chunk, read1, read2
            }

        trimmedChannel = noConnorChannel.mix(prependDoubleUMI.out)

    emit:
        trimmedChannel
}

workflow agentTrimmerWF
{
    take:
        fastqChannel

    main:
        trimmed = agentTrimmer(
            fastqChannel.map
            {
                unitId, chunk, read1, read2, hasUmi, readU, info ->
                tuple unitId, chunk, read1, read2
            })

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
            unitId, chunk, read1, read2, hasUMI, readU, info ->
            connor : params.CONNOR_COLLAPSING && hasUMI
            noConnor : true
        }

        prependSingleUMI(
            prepended.connor
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU, info ->
                tuple unitId, chunk, read1, read2, readU
            })

        noConnorChannel =
            prepended.noConnor
            .map
            {
                unitId, chunk, read1, read2, hasUmi, readU, info ->
                tuple unitId, chunk, read1, read2
            }

        trimmedChannel = noConnorChannel.mix(prependSingleUMI.out)

    emit:
        trimmedChannel
}

/*
 * Workflow to split the FASTQ reads into chunks and emit a channel of
 * per sample per chunk files for trimming and then alignment.
 *
 * In: the split FASTQ channe (unitId, chunk, read1, read2, hasUMI, readU)
 * In: the CSV channel (unitId, row)
 *
 * Out: channel (unitId, chunk, read1, read2)
 */
workflow trimming
{
    take:
        fastqChannel
        sampleInfoChannel

    main:
        withSampleInfoChannel = fastqChannel.combine(sampleInfoChannel, by: 0)

        trimOut = withSampleInfoChannel.branch
        {
            unitId, chunk, read1, read2, hasUMI, readU, info ->
            tagtrim : info['LibraryPrep'] in ['Thruplex_Tag_seq', 'Thruplex_Tag_seq_HV']
            agentTrimmer : info['LibraryPrep'] == 'Agilent_XTHS2'
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
