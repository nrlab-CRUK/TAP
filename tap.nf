#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { checkParameters; writePipelineInfo } from './functions/configuration'
include { unitIdGenerator } from './functions/functions'

include { chunkFastq } from './pipelines/splitAndMerge'
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
            .map { row -> tuple unitIdGenerator(params, row), row }

    writePipelineInfo(file("${workDir}/latest_pipeline_info.json"), params)

    chunkFastq(csvChannel)
    trimming(chunkFastq.out.fastqChannel, csvChannel)

    alignment(trimming.out, csvChannel, chunkFastq.out.chunkCountChannel)

    gatk(alignment.out) | filtering | connor | readSelection

    fastqc(filtering.out)
    publish(readSelection.out)
    ichorCNA(readSelection.out)
}
