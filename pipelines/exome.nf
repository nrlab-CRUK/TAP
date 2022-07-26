#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { connorWF as connor } from './connor'
include { picard_sortsam } from '../processes/picard'
include { gatk } from './gatk'
include { filtering } from './filtering'

workflow exome
{
    take:
        alignmentChannel
    
    main:
        // picard_sortsam(alignmentChannel)

        // gatk(alignmentChannel)

        filtering(alignmentChannel)
    
    emit:
        filtering.out
}
