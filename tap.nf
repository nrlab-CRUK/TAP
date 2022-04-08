#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { trimFASTQ; prependUMI } from './processes/fastq'
include { bwamem_pe } from './pipelines/bwamem_pe'
include { picard_sortsam } from './processes/picard'

process connor
{
    input:
        tuple val(sampleId), path(bam), path(bamIndex)

    output:
        tuple val(sampleId), path(connorFile)

    shell:
        connorFile = "${sampleId}.connor.bam"

        """
        connor -v --force \
            -s ${params.CONNOR_MIN_FAMILY_SIZE_THRESHOLD} \
            -f ${params.CONNOR_CONSENSUS_FREQ_THRESHOLD} \
            --umt_length ${params.CONNOR_UMT_LENGTH} \
            "!{bam}" \
            "!{connorFile}"
        """
}

/*
 * Main work flow.
 */
workflow
{
    csvChannel =
        channel.fromPath("alignment.csv")
            .splitCsv(header: true, quote: '"')

    fastqChannel = csvChannel
            .map {
                row ->
                // This is a bit of a hack. We'll come back to a better way to do it.
                // For SS XT, the UMI read is read 2.
                umiread = row.Read1.replaceAll(/\.r_1\./, ".r_2.")
                tuple row.PlatformUnit,
                      file("${params.FASTQ_DIR}/${row.Read1}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${row.Read2}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${umiread}", checkIfExists: true)
            }

    trimOut = fastqChannel.branch
    {
        toTrimChannel : params.TRIM_FASTQ
        noTrimChannel : true
    }

    trimFASTQ(trimOut.toTrimChannel)

    afterTrimming = trimOut.noTrimChannel.mix(trimFASTQ.out)

    prependUMI(afterTrimming)

    bwamem_pe(prependUMI.out, csvChannel) | connor | picard_sortsam
}
