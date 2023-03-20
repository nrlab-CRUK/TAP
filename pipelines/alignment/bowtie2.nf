/*
 * Bowtie2 paired end pipeline inner work flow.
 */

include { safeName } from "../../modules/nextflow-support/functions"
include { bowtie2Index } from '../../functions/references'

/*
 * Align with Bowtie2.
 */
process bowtie2
{
    cpus 4
    memory { 20.GB + 4.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(unitId), val(chunk), path(read1), path(read2), path(bowtie2IndexDir), val(bowtie2IndexPrefix)

    output:
        tuple val(unitId), val(chunk), path(outBam)

    shell:
        outBam = "${safeName(unitId)}.c_${chunk}.bam"
        template "alignment/bowtie2.sh"
}


/*
 * Bowtie2 alignment.
 *
 * In: the FASTQ channel (unitId, chunk, read1, read2)
 * In: the CSV channel (unitId, row)
 *
 * Out: BAM channel (unitId, chunk, bam) - note no index
 */
workflow bowtie2WF
{
    take:
        fastqChannel

    main:
        bowtie2IndexPath = file(bowtie2Index())
        bowtie2IndexChannel = channel.of(tuple bowtie2IndexPath.parent, bowtie2IndexPath.name)

        alignmentChannel = fastqChannel.combine(bowtie2IndexChannel)

        bowtie2(alignmentChannel)

    emit:
        bamChannel = bowtie2.out
}
