/*
 * BWAmem paired end pipeline inner work flow.
 */

include { safeName } from "../modules/nextflow-support/functions"
include { bwamem2Index } from '../functions/references'
include { addReadGroups; fixMateInformation } from "../processes/picard"

/*
 * Align with BWAmem2 (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each tuple.
 */
process bwamem2
{
    cpus 4
    memory { 20.GB + 4.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(unitId), val(chunk), path(read1), path(read2), path(bwamem2IndexDir), val(bwamem2IndexPrefix)

    output:
        tuple val(unitId), val(chunk), path(outBam)

    shell:
        outBam = "${safeName(unitId)}.c_${chunk}.bam"
        template "bwamem.sh"
}


/*
 * BWAMEM2 alignment with read group setting, mate pair fixing and merging the
 * chunked data back into a unit level file, optionally with duplicate marking.
 *
 * In: the FASTQ channel (unitId, chunk, read1, read2)
 * In: the CSV channel (unitId, row)
 *
 * Out: BAM channel (unitId, bam) - note no index
 */
workflow alignment
{
    take:
        fastqChannel
        sampleInfoChannel

    main:
        bwamem2IndexPath = file(bwamem2Index())
        bwamem2IndexChannel = channel.of(tuple bwamem2IndexPath.parent, bwamem2IndexPath.name)

        // Cannot do "each tuple" in the inputs to bwamem2 process.
        // See https://github.com/nextflow-io/nextflow/issues/1531
        alignmentChannel = fastqChannel.combine(bwamem2IndexChannel)

        // The alignment itself.
        bwamem2(alignmentChannel)

        // Add sequencing info back to the channel for read groups.
        // It is available from sampleInfoChannel, the rows from the CSV file.
        readGroupsChannel = bwamem2.out.combine(sampleInfoChannel, by: 0)

        addReadGroups(readGroupsChannel) | fixMateInformation

    emit:
        bamChannel = fixMateInformation.out
}
