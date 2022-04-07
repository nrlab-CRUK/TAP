#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process trimFASTQ
{
    input:
        tuple val(sampleId), path(read1), path(read2)
    
    output:
        tuple val(sampleId), path("trimmed/${read1}"), path("trimmed/${read2}")
        
    shell:
        
        """
        mkdir trimmed
        java -jar /opt/AGeNT/SurecallTrimmer_v4.0.1.jar \
            -fq1 "!{read1}" -fq2 "!{read2}" \
            -xt -minFractionRead !{params.TRIM_MINIMUM_FRACTION_READ} -qualityTrimming !{params.TRIM_QUALITY_THRESHOLD} \
            -out_loc trimmed
        """
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
