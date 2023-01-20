#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { safeName } from "./modules/nextflow-support/functions"
include { checkParameters; checkDriverCSV; writePipelineInfo } from './functions/configuration'
include { unitIdGenerator } from './functions/functions'

include { chunkFastq; mergeAlignedChunks } from './pipelines/splitAndMerge'
include { trimming } from './pipelines/trimming'
include { alignment } from './pipelines/alignment'
include { gatk } from './pipelines/gatk'
include { fastqc } from './processes/fastqc'
include { publish; checksum } from './processes/finishing'
include { recording as recordRun } from './pipelines/recording'

if (!checkParameters(params))
{
    exit 1
}
if (!checkDriverCSV(params))
{
    exit 1
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

    fastqc(publish.out)
    checksum(publish.out)

    recordRun(csvChannel, publish.out)
}
