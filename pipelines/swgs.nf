#!/usr/bin/env nextflow

include { picard_sortsam } from '../processes/picard'
include { filtering } from './filtering'

process fastqc
{
    memory '300m'
    time   '4h'
    cpus   1
    
    publishDir "${launchDir}/reports", mode: 'link'
    
    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)
    
    output:
        path("${sampleId}_fastqc.html")
        
    shell:
        canonicalBam = "${sampleId}.bam"
        
        """
        mkdir temp
        
        ln "!{bamFile}" "!{canonicalBam}"

        fastqc \
            --threads !{task.cpus} \
            --dir temp \
            --extract \
            "!{canonicalBam}"
        
        rm -rf temp
        """
}

workflow sWGS
{
    take:
        alignmentChannel
        sampleInfoChannel
    
    main:
        // picard_sortsam(alignmentChannel)

        filtering(alignmentChannel)
        
        fastqc(filtering.out)
        
    emit:
        filtering.out
}
