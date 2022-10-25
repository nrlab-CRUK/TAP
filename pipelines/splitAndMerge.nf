@Grab('org.apache.commons:commons-lang3:3.12.0')

import static org.apache.commons.lang3.StringUtils.isNotBlank

include { sizeOf } from '../functions/functions'
include { extractChunkNumber; splitFastq as splitFastq1; splitFastq as splitFastq2; splitFastq as splitFastqU } from "../processes/fastq"


/*
 * Workflow to split the FASTQ reads into chunks and emit a channel of
 * per sample per chunk files for trimming and then alignment.
 *
 * In: the CSV channel (unitId, row)
 *
 * Out: channel (unitId, chunk, read1, read2, hasUMI, readU)
 */
workflow chunkFastq
{
    take:
        csvChannel

    main:
        // A path to the empty FASTQ file. Used when there is no UMI read.

        emptyFile = file("${projectDir}/resources/no_umi.fq")

        // Branch into two channels for UMI splitting:
        // with and without a UMI file.

        umiChannels =
            csvChannel
            .branch
            {
                unitId, info ->
                withUMI:    isNotBlank(info.UmiRead)
                withoutUMI: true
            }

        // Split into three channels, one read in each, for fastq splitting.

        read1Channel =
            csvChannel
            .map
            {
                unitId, info ->
                tuple unitId, 1, file("${params.FASTQ_DIR}/${info.Read1}", checkIfExists: true)
            }

        read2Channel =
            csvChannel
            .map
            {
                unitId, info ->
                tuple unitId, 2, file("${params.FASTQ_DIR}/${info.Read2}", checkIfExists: true)
            }

        readUChannel =
            umiChannels.withUMI
            .map
            {
                unitId, info ->
                tuple unitId, 'U', file("${params.FASTQ_DIR}/${info.UmiRead}", checkIfExists: true)
            }

        splitFastq1(read1Channel)
        splitFastq2(read2Channel)
        splitFastqU(readUChannel)

        // Get the number of chunks for each sample id (same for all channels).

        chunkCountChannel =
            splitFastq1.out
            .map
            {
                unitId, read, fastqFiles ->
                tuple unitId, sizeOf(fastqFiles)
            }

        // Create a channel of samples that do not have a UMI read
        // to give a reference to the empty file repeated for the
        // number of chunks found from splitting read one. This allows it
        // to be combined with reads 1 & 2 below without remainder.

        noUmiChannel =
            umiChannels.withoutUMI
            .combine(chunkCountChannel, by: 0)
            .map
            {
                unitId, info, size ->
                tuple unitId, 1..size, false, emptyFile
            }
            .transpose()

        // Flatten the list of files in all channels to have three channels with
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

        perChunkChannelU =
            splitFastqU.out
            .transpose()
            .map
            {
                unitId, read, fastq ->
                tuple unitId, extractChunkNumber(fastq), true, fastq
            }
            .mix(noUmiChannel)

        // Combine these channels by base name and chunk number, and present the
        // three individual files and UMI flag in a tuple.

        combinedChunkChannel =
            perChunkChannel1
            .join(perChunkChannel2, by: 0..1)
            .join(perChunkChannelU, by: 0..1)

        /*
        combinedChunkChannel.view
        {
            unitId, chunk, r1, r2, hasUMI, rU ->
            "${unitId} (chunk ${chunk}) ${hasUMI ? 'UMI' : 'no UMI'}: ${r1.name} ${r2.name} ${rU.name}"
        }
        */

    emit:
        fastqChannel = combinedChunkChannel
        chunkCountChannel
}
