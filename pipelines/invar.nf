#!/usr/bin/env nextflow

include { connorWF as connor } from './connor'
include { picard_sortsam } from '../processes/picard'
include { gatk } from './gatk'
include { filtering } from './filtering'

workflow invar
{
    take:
        alignmentChannel
        
    main:
        connor(alignmentChannel) | picard_sortsam | filtering
        
    emit:
        filtering.out
}
