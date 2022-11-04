#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { checkParameters; checkDriverCSV; writePipelineInfo } from './functions/configuration'
include { unitIdGenerator; safeName } from './functions/functions'

include { chunkFastq; mergeAlignedChunks } from './pipelines/splitAndMerge'
include { trimming } from './pipelines/trimming'
include { alignment } from './pipelines/alignment'
include { gatk } from './pipelines/gatk'
include { fastqc } from './processes/fastqc'
include { recording as recordRun } from './pipelines/recording'

if (!checkParameters(params))
{
    exit 1
}
if (!checkDriverCSV(params))
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
        safeSampleId = safeName(sampleId)
        finalBam = "${safeSampleId}.bam"
        finalIndex = "${safeSampleId}.bai"

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

    alignment(trimming.out, csvChannel)

    mergeAlignedChunks(alignment.out, csvChannel, chunkFastq.out.chunkCountChannel)

    gatk(mergeAlignedChunks.out)

    publish(gatk.out)
    
    recordRun(csvChannel, publish.out)
}
