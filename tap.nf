#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { trimGalore; tagtrim } from './processes/trimming'
include { prependUMI } from './processes/fastq'
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
                tuple row.PlatformUnit,
                      row['Index Type'],
                      file("${params.FASTQ_DIR}/${row.Read1}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${row.Read2}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${row.UmiRead}", checkIfExists: false)
            }

    trimOut = fastqChannel.branch
    {
        tagtrimChannel : params.TRIM_FASTQ && it[1] == 'ThruPLEX DNA-seq Dualindex'
        trimGaloreChannel : params.TRIM_FASTQ
        noTrimChannel : true
    }


    trimGalore(trimOut.trimGaloreChannel)

    tagtrim(trimOut.tagtrimChannel)

    afterTrimming = trimOut.noTrimChannel.mix(trimGalore.out).mix(tagtrim.out)

    // prependUMI(afterTrimming)

    // bwamem_pe(prependUMI.out, csvChannel) | connor | picard_sortsam
}
