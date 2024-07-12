#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { safeName } from "./modules/nextflow-support/functions"
include { checkParameters; checkDriverCSV; writePipelineInfo } from './functions/configuration'
include { unitIdGenerator } from './functions/functions'

include { chunkFastq; mergeAlignedChunks } from './pipelines/splitAndMerge'
include { trimming } from './pipelines/trimming'
include { postAlignment } from './pipelines/alignment/postAlignment'
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

switch (params.ALIGNER.toLowerCase())
{
    case 'bwamem':
    case 'bwa_mem':
    case 'bwa-mem':
    case 'bwamem2':
    case 'bwa_mem2':
    case 'bwa-mem2':
        include { bwamem2WF as alignment } from "./pipelines/alignment/bwamem2"
        break

    case 'bowtie':
    case 'bowtie2':
        include { bowtie2WF as alignment } from "./pipelines/alignment/bowtie2"
        break

    case 'bwameth':
    case 'bwa-meth':
    case 'bwa_meth':
        include { bwamethWF as alignment } from "./pipelines/alignment/bwameth"
        break

    default:
        exit 1, "Aligner must be one of 'bwamem2', 'bowtie2' or 'bwameth'."
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

    alignment(trimming.out)
    postAlignment(alignment.out, csvChannel)

    mergeAlignedChunks(postAlignment.out, csvChannel, chunkFastq.out.chunkCountChannel)

    gatk(mergeAlignedChunks.out)

    publish(gatk.out)

    fastqc(publish.out)
    checksum(publish.out)

    /*
    recordRun(csvChannel, publish.out)
    */
}
