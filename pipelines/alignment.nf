/*
 * BWAmem paired end pipeline inner work flow.
 */

include { safeName } from '../functions/functions'
include { picard_addreadgroups; picard_fixmate; picard_merge_or_markduplicates } from "../processes/picard"

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
 * In: the group sizing channel for each unit (unitId, size) from "chunkFastq".
 *
 * Out: BAM channel (unitId, bam, bamIndex)
 */
workflow alignment
{
    take:
        fastqChannel
        sampleInfoChannel
        chunkCountChannel

    main:
        bwamem2IndexPath = file(params.BWAMEM2_INDEX)
        bwamem2IndexChannel = channel.of(tuple bwamem2IndexPath.parent, bwamem2IndexPath.name)

        // Cannot do "each tuple" in the inputs to bwamem2 process.
        // See https://github.com/nextflow-io/nextflow/issues/1531
        alignmentChannel = fastqChannel.combine(bwamem2IndexChannel)

        // The alignment itself.
        bwamem2(alignmentChannel)

        // Add sequencing info back to the channel for read groups.
        // It is available from sampleInfoChannel, the rows from the CSV file.
        readGroupsChannel = bwamem2.out.combine(sampleInfoChannel, by: 0)

        picard_addreadgroups(readGroupsChannel) | picard_fixmate

        // Combine the groups with groupTuple but using a group key with the
        // number of chunks as made by chunkCountChannel. This allows groupTuple
        // to know when each grouping has got all its bits together (i.e. all the
        // chunks are done).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        groupedBamChannel =
            picard_fixmate.out.combine(chunkCountChannel, by: 0)
            .map
            {
                unitId, bamFile, groupSize ->
                tuple groupKey(unitId, groupSize), bamFile
            }
            .groupTuple()

        // Group the outputs by base name.
        picard_merge_or_markduplicates(groupedBamChannel)

    emit:
        bamChannel = picard_merge_or_markduplicates.out.merged_bam
}
