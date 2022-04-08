/*
 * BWAmem paired end pipeline inner work flow.
 */

include { extractChunkNumber; splitFastq as splitFastq1; splitFastq as splitFastq2 } from "../processes/fastq"
include { picard_addreadgroups; picard_fixmate; picard_merge_or_markduplicates } from "../processes/picard"

/*
 * Align with BWAmem (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each tuple.
 */
process bwa_mem
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(sampleId), path(sequenceFiles), path(bwamem2IndexDir), val(bwamem2IndexPrefix)

    output:
        tuple val(sampleId), val(chunk), path(outBam)

    shell:
        chunk = extractChunkNumber(sequenceFiles[0])

        outBam = "${sampleId}.${chunk}.bam"
        template "bwamem.sh"
}


workflow bwamem_pe
{
    take:
        fastqChannel
        csvChannel

    main:
        bwamem2IndexPath = file(params.BWAMEM2_INDEX)
        bwamem2IndexChannel = channel.of(tuple bwamem2IndexPath.parent, bwamem2IndexPath.name)

        // Split into two channels, one read in each, for fastq splitting.

        read1Channel =
            fastqChannel
            .map
            {
                sampleId, read1, read2 ->
                tuple sampleId, 1, read1
            }

        read2Channel =
            fastqChannel
            .map
            {
                sampleId, read1, read2 ->
                tuple sampleId, 2, read2
            }

        splitFastq1(read1Channel)
        splitFastq2(read2Channel)

        // Flatten the list of files in both channels to have two channels with
        // a single file per item. Also extract the chunk number from the file name.

        perChunkChannel1 =
            splitFastq1.out
            .transpose()
            .map
            {
                sampleId, read, fastq ->
                tuple sampleId, extractChunkNumber(fastq), fastq
            }

        perChunkChannel2 =
            splitFastq2.out
            .transpose()
            .map
            {
                sampleId, read, fastq ->
                tuple sampleId, extractChunkNumber(fastq), fastq
            }

        // Combine these channels by base name and chunk number, and present the
        // two individual files as a list of two.

        combinedChunkChannel = perChunkChannel1
            .combine(perChunkChannel2, by: 0..1)
            .map
            {
                sampleId, chunk, r1, r2 ->
                tuple sampleId, [ r1, r2 ]
            }
            .combine(bwamem2IndexChannel)

        bwa_mem(combinedChunkChannel)

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        readGroupsChannel = bwa_mem.out
            .combine(csvChannel.map { tuple it.PlatformUnit, it }, by: 0)

        picard_addreadgroups(readGroupsChannel)
        picard_fixmate(picard_addreadgroups.out)

        // Group the outputs by base name.
        picard_merge_or_markduplicates(picard_fixmate.out.groupTuple())

    emit:
        bamChannel = picard_merge_or_markduplicates.out.merged_bam
}
