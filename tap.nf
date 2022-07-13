#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { trimGaloreWF as trimGalore; tagtrimWF as tagtrim; noTrimWF as notrim } from './pipelines/trimming'
include { bwamem_pe } from './pipelines/bwamem_pe'
include { connorWF as connor } from './pipelines/connor'
include { picard_sortsam } from './processes/picard'

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
                      row.UmiRead ? file("${params.FASTQ_DIR}/${row.UmiRead}", checkIfExists: true) : null
            }

    trimOut = fastqChannel.branch
    {
        tagtrim : it[1] == 'ThruPLEX DNA-seq Dualindex'
        trimGalore : params.TRIM_FASTQ
        noTrim : true
    }

    galoreTrimmedChannel = trimGalore(trimOut.trimGalore)

    tagtrimTrimmedChannel = tagtrim(trimOut.tagtrim)

    noTrimChannel = notrim(trimOut.noTrim)

    afterTrimming = noTrimChannel.mix(galoreTrimmedChannel).mix(tagtrimTrimmedChannel)

    bwamem_pe(afterTrimming, csvChannel) | connor | picard_sortsam
}
