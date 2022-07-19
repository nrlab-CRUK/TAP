#!/usr/bin/env nextflow

import groovy.grape.Grape

nextflow.enable.dsl = 2

include { trimGaloreWF as trimGalore; tagtrimWF as tagtrim; noTrimWF as notrim } from './pipelines/trimming'
include { bwamem_pe } from './pipelines/bwamem_pe'
include { connorWF as connor } from './pipelines/connor'
include { picard_sortsam } from './processes/picard'
include { gatk } from './pipelines/gatk'

// Grab the necessary grapes for Groovy here, so make sure they are available
// before the pipeline starts and multiple processes try to get them.
def grabGrapes()
{
    log.debug("Fetching Groovy dependencies.")
    
    def classLoader = nextflow.Nextflow.classLoader
    
    Grape.grab([group:'com.github.samtools', artifact:'htsjdk', version:'2.24.1', noExceptions:true, classLoader: classLoader])
    Grape.grab([group:'info.picocli', artifact:'picocli', version:'4.6.3', classLoader: classLoader])
    Grape.grab([group:'org.apache.logging.log4j', artifact:'log4j-api', version:'2.17.2', classLoader: classLoader])
    Grape.grab([group:'org.apache.logging.log4j', artifact:'log4j-core', version:'2.17.2', classLoader: classLoader])
}

/*
 * Main work flow.
 */
workflow
{
    grabGrapes()
    
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
    
    gatk(picard_sortsam.out)
}
