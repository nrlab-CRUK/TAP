#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process trimFASTQ
{
    input:
        tuple val(sampleId), path(read1), path(read2)

    output:
        tuple val(sampleId), path("${read1.baseName}*.fastq.gz"), path("${read2.baseName}*.fastq.gz")

    shell:
        template "trim.sh"
}

/*
process prependUMI
{
    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)
        
    shell:
    
    
}
*/

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
                tuple row.PlatformUnit,
                      file("${params.FASTQ_DIR}/${row.Read1}", checkIfExists: true),
                      file("${params.FASTQ_DIR}/${row.Read2}", checkIfExists: true)
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
