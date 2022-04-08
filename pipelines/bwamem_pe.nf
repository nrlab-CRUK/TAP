/*
 * BWAmem paired end pipeline inner work flow.
 */

include { extractChunkNumber; splitFastq as split_fastq_1; splitFastq as split_fastq_2 } from "../processes/fastq"
include { pairedend } from "./pairedend"

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
        fastq_channel
        csv_channel

    main:
        bwamem2_index_path = file(params.BWAMEM2_INDEX)
        bwamem2_index_channel = channel.of(tuple bwamem2_index_path.parent, bwamem2_index_path.name)

        // Split into two channels, one read in each, for fastq splitting.

        read1_channel =
            fastq_channel
            .map
            {
                sampleId, read1, read2 ->
                tuple sampleId, 1, read1
            }

        read2_channel =
            fastq_channel
            .map
            {
                sampleId, read1, read2 ->
                tuple sampleId, 2, read2
            }

        split_fastq_1(read1_channel)
        split_fastq_2(read2_channel)

        // Flatten the list of files in both channels to have two channels with
        // a single file per item. Also extract the chunk number from the file name.

        per_chunk_channel_1 =
            split_fastq_1.out
            .transpose()
            .map
            {
                sampleId, read, fastq ->
                tuple sampleId, extractChunkNumber(fastq), fastq
            }

        per_chunk_channel_2 =
            split_fastq_2.out
            .transpose()
            .map
            {
                sampleId, read, fastq ->
                tuple sampleId, extractChunkNumber(fastq), fastq
            }

        // Combine these channels by base name and chunk number, and present the
        // two individual files as a list of two.

        combined_chunk_channel = per_chunk_channel_1
            .combine(per_chunk_channel_2, by: 0..1)
            .map
            {
                sampleId, chunk, r1, r2 ->
                tuple sampleId, [ r1, r2 ]
            }
            .combine(bwamem2_index_channel)

        bwa_mem(combined_chunk_channel)
        pairedend(bwa_mem.out, csv_channel)
}
