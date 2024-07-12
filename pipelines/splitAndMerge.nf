@Grab('org.apache.commons:commons-lang3:3.12.0')

import static org.apache.commons.lang3.StringUtils.isNotBlank

include { sizeOf } from "../modules/nextflow-support/functions"
include { sampleIdGenerator } from '../functions/functions'
include { extractChunkNumber; splitFastq as splitFastq1; splitFastq as splitFastq2; splitFastq as splitFastqU } from "../processes/fastq"
include { mergeOrMarkDuplicates } from "../processes/picard"


/*
 * Workflow to split the FASTQ reads into chunks and emit a channel of
 * per sample per chunk files for trimming and then alignment.
 *
 * In: the CSV channel (unitId, row)
 *
 * Out: channel (unitId, chunk, read1, read2)
 */
workflow chunkFastq
{
    take:
        csvChannel

    main:
        // Split into two channels, one read in each, for fastq splitting.
        // If there is a UMI read, this is passed to the splitter too. That program
        // puts the UMI in the read header from the extra file.

        read1Channel =
            csvChannel
            .map
            {
                unitId, info ->
                def theseReads = []
                theseReads << file("${params.FASTQ_DIR}/${info.Read1}", checkIfExists: true)
                if (isNotBlank(info.UmiRead))
                {
                    theseReads << file("${params.FASTQ_DIR}/${info.UmiRead}", checkIfExists: true)
                }
                tuple unitId, 1, theseReads
            }

        read2Channel =
            csvChannel
            .map
            {
                unitId, info ->
                def theseReads = []
                theseReads << file("${params.FASTQ_DIR}/${info.Read2}", checkIfExists: true)
                if (isNotBlank(info.UmiRead))
                {
                    theseReads << file("${params.FASTQ_DIR}/${info.UmiRead}", checkIfExists: true)
                }
                tuple unitId, 2, theseReads
            }

        splitFastq1(read1Channel)
        splitFastq2(read2Channel)

        // Get the number of chunks for each sample id (same for all channels).

        chunkCountChannel =
            splitFastq1.out
            .map
            {
                unitId, read, fastqFiles ->
                tuple unitId, sizeOf(fastqFiles)
            }

        // Flatten the list of files in all channels to have two new channels with
        // a single file per item. Also extract the chunk number from the file name.
        // UMI read channel will be a mix of split given UMI files and
        // replicated (for number of chunks) empty files.

        perChunkChannel1 =
            splitFastq1.out
            .transpose()
            .map
            {
                unitId, read, fastq ->
                tuple unitId, extractChunkNumber(fastq), fastq
            }

        perChunkChannel2 =
            splitFastq2.out
            .transpose()
            .map
            {
                unitId, read, fastq ->
                tuple unitId, extractChunkNumber(fastq), fastq
            }

        // Combine these channels by base name and chunk number, and present the
        // two individual files in a tuple.

        combinedChunkChannel = perChunkChannel1.join(perChunkChannel2, by: 0..1)

        /*
        combinedChunkChannel.view
        {
            unitId, chunk, r1, r2 ->
            "${unitId} (chunk ${chunk}): ${r1.name} ${r2.name}"
        }
        */

    emit:
        fastqChannel = combinedChunkChannel
        chunkCountChannel
}


workflow mergeAlignedChunks
{
    take:
        bamChannel
        sampleInfoChannel
        chunkCountChannel

    main:
        // Work out how many chunks each *sample* will be expecting. This is
        // the sum of the group sizes for each unit within the sample.

        sampleCountsChannel =
            chunkCountChannel
            .combine(sampleInfoChannel, by: 0)
            .map
            {
                unitId, groupSize, info ->
                tuple sampleIdGenerator(params, info), groupSize
            }
            .groupTuple()
            .map
            {
                sampleId, groupSizes ->
                tuple sampleId, groupSizes.sum()
            }

        // Group the BAM files by sample id. Clues to how many files are expected in each
        // sample come from sampleCountsChannel.

        groupedBamChannel =
            bamChannel
            .combine(sampleInfoChannel, by: 0)
            .map
            {
                unitId, bamFile, info ->
                tuple sampleIdGenerator(params, info), bamFile
            }
            .combine(sampleCountsChannel, by: 0)
            .map
            {
                sampleId, bamFile, fileCount ->
                tuple groupKey(sampleId, fileCount), bamFile
            }
            .groupTuple()

        // Merge the groups of chunks together to form whole sample BAM files.

        mergeOrMarkDuplicates(groupedBamChannel)

    emit:
        bamChannel = mergeOrMarkDuplicates.out.merged_bam
}
