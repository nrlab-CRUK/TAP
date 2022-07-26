/*
 * BWAmem paired end pipeline inner work flow.
 */

include { extractChunkNumber; splitFastq as splitFastq1; splitFastq as splitFastq2 } from "../processes/fastq"
include { picard_addreadgroups; picard_fixmate; picard_merge_or_markduplicates } from "../processes/picard"

/*
 * Align with BWAmem2 (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each tuple.
 */
process bwamem2
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


workflow alignment
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

        // Get the number of chunks for each sample id (same for both channels).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitFastq1.out
            .map
            {
                sampleId, read, fastqFiles ->
                // Fastq files can be a single path or it can be a list of paths.
                // Ideally, Nextflow would always return a list, even of length 1.
                // See https://github.com/nextflow-io/nextflow/issues/2425
                fastqFiles instanceof Collection
                    ? tuple(sampleId, fastqFiles.size())
                    : tuple(sampleId, 1)
            }

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

        bwamem2(combinedChunkChannel)

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        readGroupsChannel = bwamem2.out
            .combine(csvChannel.map { tuple it.PlatformUnit, it }, by: 0)

        picard_addreadgroups(readGroupsChannel)
        picard_fixmate(picard_addreadgroups.out)

        // Combine the groups with groupTuple but using a group key with the
        // number of chunks as made by chunkCountChannel. This allows groupTuple
        // to know when each grouping has got all its bits together (i.e. all the
        // chunks are done).

        groupedBamChannel =
            picard_fixmate.out.combine(chunkCountChannel, by: 0)
            .map
            {
                sampleId, bamFile, groupSize ->
                tuple groupKey(sampleId, groupSize), bamFile
            }
            .groupTuple()

        // Group the outputs by base name.
        picard_merge_or_markduplicates(groupedBamChannel)

    emit:
        bamChannel = picard_merge_or_markduplicates.out.merged_bam
}
