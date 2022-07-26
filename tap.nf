#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { grabGrapes } from './functions/initialisation'
include { getExperimentType } from './functions/databaseAdditions'

include { trimGaloreWF as trimGalore; tagtrimWF as tagtrim; noTrimWF as notrim } from './pipelines/trimming'
include { alignment } from './pipelines/alignment'
include { exome } from './pipelines/exome'
include { sWGS } from './pipelines/swgs'


def isExome(info)
{
    def exome = info.ExperimentType in ['exome', 'exome_Sequencing']
    // log.warn("${info.PlatformUnit} type is ${info.ExperimentType} - isExome = ${exome}")
    return exome
}

def isWGS(info)
{
    def wgs = info.ExperimentType in ['sWGS', 'WGS']
    // log.warn("${info.PlatformUnit} type is ${info.ExperimentType} - isWGS = ${wgs}")
    return wgs
}

process readyToPublish
{
    executor 'local'
    memory   '1m'
    time     '2m'
    
    stageInMode 'link'
    publishDir "${launchDir}/processed", mode: 'link'
    
    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)
        
    output:
        tuple val(sampleId), path(finalBam), path(finalIndex)
        
    shell:
        finalBam = "${sampleId}.bam"
        finalIndex = "${sampleId}.bai"
        
        """
            if [ "!{bamFile}" != "!{finalBam}" ]
            then
                ln "!{bamFile}" "!{finalBam}"
                ln "!{bamIndex}" "!{finalIndex}"
            fi
        """
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
            
    sampleInfoChannel = csvChannel
            .map {
                row ->
                
                // Add database fields
                row['ExperimentType'] = getExperimentType(row.SLXId)
                
                tuple row.PlatformUnit, row
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

    alignment(afterTrimming, csvChannel)
    
    // Get the information back into the channel
    
    alignedWithInfoChannel = alignment.out.combine(sampleInfoChannel, by: 0)
    
    typeChannel = alignedWithInfoChannel.branch
    {
        exome: isExome(it[3])
        sWGS:  isWGS(it[3])
        other: true
    }
    
    exome(typeChannel.exome.map { s, b, i, info -> tuple s, b, i })
    
    sWGS(typeChannel.sWGS.map { s, b, i, info -> tuple s, b, i }, sampleInfoChannel)
    
    finalChannel = exome.out.mix(sWGS.out).mix(typeChannel.other.map { s, b, i, info -> tuple s, b, i })
    
    readyToPublish(finalChannel)
}
