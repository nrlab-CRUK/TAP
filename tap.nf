#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { checkParameters } from './functions/configuration'

include { trimming } from './pipelines/trimming'
include { connorWF as connor } from './pipelines/connor'
include { alignment } from './pipelines/alignment'
include { gatk } from './pipelines/gatk'
include { filtering } from './pipelines/filtering'
include { readSelectionWF as readSelection } from './pipelines/readSelection'
include { fastqc } from './processes/fastqc'
include { ichorCNAWF as ichorCNA } from './pipelines/ichorCNA'

if (!checkParameters(params))
{
    exit 1
}

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

process publish
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
    csvChannel =
        channel.fromPath("${params.INPUTS_CSV}", checkIfExists: true)
            .splitCsv(header: true, quote: '"')

    // TODO check the PlatformUnit column exists

    fastqChannel = csvChannel
            .map {
                row ->
                tuple row.PlatformUnit,
                      file("${params.FASTQ_DIR}/${row.Read1}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${row.Read2}", checkIfExists: true),
                      row.UmiRead ? file("${params.FASTQ_DIR}/${row.UmiRead}", checkIfExists: true)
                                  : file("${projectDir}/resources/no_umi.fq", checkIfExists: true)
            }

    sampleInfoChannel = csvChannel
            .map {
                row ->
                tuple row.PlatformUnit, row
            }

    trimming(fastqChannel, sampleInfoChannel)

    alignment(trimming.out, sampleInfoChannel) | gatk | filtering | connor | readSelection

    fastqc(filtering.out)
    publish(readSelection.out)
    ichorCNA(readSelection.out)
}
