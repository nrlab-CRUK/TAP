/*
 * Trimming processes.
 */

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
    memory '1G'

    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread), val(info)

    output:
        tuple val(sampleId), path("${fileBase}_val_1.fq.gz"), path("${fileBase}_val_2.fq.gz"), path(umiread)

    shell:
        fileBase = baseName(read1)

        template "trimming/trimGalore.sh"
}

process tagtrim
{
    cpus   5
    memory '256M'

    input:
        tuple val(sampleId), path(read1In), path(read2In), path(umiRead), val(info)

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

process prependSingleUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        seqkit concat -w 0 "!{umiread}" "!{read1}" -o "!{read1out}"
        seqkit concat -w 0 "!{umiread}" "!{read2}" -o "!{read2out}"
        """
}

process prependDoubleUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    input:
        tuple val(sampleId), path(read1), path(read2), path(umi1), path(umi2)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        seqkit concat -w 0 "!{umi1}" "!{read1}" -o "!{read1out}"
        seqkit concat -w 0 "!{umi2}" "!{read2}" -o "!{read2out}"
        """
}


workflow trimGaloreWF
{
    take:
        fastqChannel

    main:
        trimmed = trimGalore(fastqChannel)

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        prependSingleUMI(prepended.connor)

        noConnorChannel = prepended.noConnor.map { s, r1, r2, rU -> tuple s, r1, r2 }

        trimmedChannel = noConnorChannel.mix(prependSingleUMI.out)

    emit:
        trimmedChannel
}

workflow tagtrimWF
{
    take:
        fastqChannel

    main:
        trimmed = tagtrim(fastqChannel)

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

workflow noTrimWF
{
    take:
        fastqChannel

    main:
        withoutInfoChannel = fastqChannel.map { s, r1, r2, rU, info -> tuple s, r1, r2, rU }

        prepended = withoutInfoChannel.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        prependSingleUMI(prepended.connor)

        noConnorChannel = prepended.noConnor.map { s, r1, r2, rU -> tuple s, r1, r2 }

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
            tagtrim : it[4]['Index Type'] == 'ThruPLEX DNA-seq Dualindex'
            trimGalore : params.TRIM_FASTQ
            noTrim : true
        }

        trimGaloreWF(trimOut.trimGalore)
        tagtrimWF(trimOut.tagtrim)
        noTrimWF(trimOut.noTrim)

        afterTrimmingChannel = noTrimWF.out.mix(trimGaloreWF.out).mix(tagtrimWF.out)

    emit:
        afterTrimmingChannel
}
