#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process trimFASTQ
{
    input:
        tuple val(sampleId), path(read1), path(read2)

    output:
        tuple val(sampleId), path("trimmed/${read1}"), path("trimmed/${read2}")

    shell:
        template "trim.sh"
}

/*
 * Main work flow.
 */
workflow
{
    fastqChannel =
        channel.fromPath("alignment.csv")
            .splitCsv(header: true, quote: '"')
            .map {
                row ->
                tuple row.PlatformUnit, file(row.Read1), file(row.Read2)
            }

    trimOut = fastqChannel.branch
    {
        toTrimChannel : params.TRIM_FASTQ
        noTrimChannel : true
    }

    trimFASTQ(trimOut.toTrimChannel)

    afterTrimming = trimOut.noTrimChannel.mix(trimFASTQ.out)

    afterTrimming.view()
}
