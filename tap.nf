#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { bwamem_pe } from './pipelines/bwamem_pe'

process trimFASTQ
{
    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path("${read1.baseName}*.fastq.gz"), path("${read2.baseName}*.fastq.gz"), path(umiread)

    shell:
        template "trim.sh"
}

process prependUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        template "prependUMI.sh"
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

    bwamem_pe(prependUMI.out, csvChannel)
}
