/*
 * Trimming processes.
 */

include { javaMemoryOptions; safeName } from "../modules/nextflow-support/functions"
include { hasUMIs } from '../functions/functions'

def baseName(fastqFile)
{
    def name = fastqFile.name
    name = name.replaceAll(/\.(fq|fastq)(\.gz)?$/, "")
    name = name.replaceAll(/\.r_\d$/, "")
    return name
}

process trimGalore
{
    cpus   8
    memory 1.GB
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In), val(libraryPrep)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

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
        tuple val(unitId), val(chunk), path(read1In), path(read2In), val(libraryPrep)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}.r_1.tagtrim.fq.gz"
        read2Out = "${outFilePrefix}.r_2.tagtrim.fq.gz"

        template "trimming/tagtrim.sh"
}

process agentTrimmer
{
    cpus   4
    memory { 4.GB * task.attempt }
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In), val(libraryPrep)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        javaMem = javaMemoryOptions(task).jvmOpts
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}_R1.fastq.gz"
        read2Out = "${outFilePrefix}_R2.fastq.gz"
        umiOut = "${outFilePrefix}_MBC.txt.gz"

        template "trimming/agentTrimmer.sh"
}

process trimmomatic
{
    cpus   16
    memory 1.GB
    time { 12.hour * task.attempt }
    maxRetries 1

    input:
        tuple val(unitId), val(chunk), path(read1In), path(read2In), val(libraryPrep)

    output:
        tuple val(unitId), val(chunk), path(read1Out), path(read2Out)

    shell:
        javaMem = javaMemoryOptions(task).jvmOpts
        outFilePrefix = "${safeName(unitId)}.c_${chunk}"
        read1Out = "${outFilePrefix}_R1.fastq.gz"
        read2Out = "${outFilePrefix}_R2.fastq.gz"

        template "trimming/trimmomatic.sh"
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

process prependIlluminaUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

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
        python3 "${projectDir}/python/PrependUMI.py" \
            --source "!{read1In}" \
            --output "!{read1Out}"
        python3 "${projectDir}/python/PrependUMI.py" \
            --source "!{read2In}" \
            --output "!{read2Out}"
        """
}


workflow trimGaloreWF
{
    take:
        fastqChannel

    main:
        trimmed = trimGalore(fastqChannel)

        // only prepend UMI read if there are UMIs in the read headers
        // AND Connor UMI-based deduplication is requested

        prepended = trimmed.branch
        {
            unitId, chunk, read1, read2 ->
            connor : params.CONNOR_COLLAPSING && hasUMIs(read1)
            noConnor : true
        }

        prependIlluminaUMI(prepended.connor)

        trimmedChannel = prepended.noConnor.mix(prependIlluminaUMI.out)

    emit:
        trimmedChannel
}

workflow tagtrimWF
{
    take:
        fastqChannel

    main:
        trimmed = tagtrim(fastqChannel)

        // only prepend the extracted UMI reads from tagtrim if Connor
        // deduplication is requested

        prepended = trimmed.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        prependIlluminaUMI(prepended.connor)

        trimmedChannel = prepended.noConnor.mix(prependIlluminaUMI.out)

    emit:
        trimmedChannel
}

workflow agentTrimmerWF
{
    take:
        fastqChannel

    main:
        trimmed = agentTrimmer(fastqChannel)

        // only prepend the extracted UMI from AGeNT trimmer if Connor
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

workflow trimmomaticWF
{
    take:
        fastqChannel

    main:
        trimmomatic(fastqChannel)

    emit:
        trimmedChannel = trimmomatic.out
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
            unitId, chunk, read1, read2, libraryPrep ->
            connor : params.CONNOR_COLLAPSING && hasUMIs(read1)
            noConnor : true
        }

        prependIlluminaUMI(prepended.connor)

        noConnorChannel =
            prepended.noConnor
            .map
            {
                unitId, chunk, read1, read2, libraryPrep ->
                tuple unitId, chunk, read1, read2
            }

        trimmedChannel = noConnorChannel.mix(prependIlluminaUMI.out)

    emit:
        trimmedChannel
}

/*
 * Workflow to split the FASTQ reads into chunks and emit a channel of
 * per sample per chunk files for trimming and then alignment.
 *
 * In: the split FASTQ channel (unitId, chunk, read1, read2)
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
        trimChoice =
            fastqChannel
            .combine(sampleInfoChannel, by: 0)
            .map
            {
                unitId, chunk, read1, read2, info ->
                tuple unitId, chunk, read1, read2, info['LibraryPrep']
            }
            .branch
            {
                unitId, chunk, read1, read2, libraryPrep ->
                tagtrim : libraryPrep == 'Thruplex_Tag_seq'
                agentTrimmer : libraryPrep == 'Agilent_XTHS2'
                trimmomatic : libraryPrep == 'Thruplex_Tag_seq_HV'
                trimGalore : params.TRIM_FASTQ
                noTrim : true
            }

        trimGaloreWF(trimChoice.trimGalore)
        tagtrimWF(trimChoice.tagtrim)
        agentTrimmerWF(trimChoice.agentTrimmer)
        trimmomaticWF(trimChoice.trimmomatic)
        noTrimWF(trimChoice.noTrim)

        afterTrimmingChannel = noTrimWF.out.mix(trimGaloreWF.out).mix(tagtrimWF.out).mix(agentTrimmerWF.out).mix(trimmomaticWF.out)

    emit:
        afterTrimmingChannel
}
