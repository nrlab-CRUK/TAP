/*
 * Preprocessing processes.
 */

include { safeName } from "../modules/nextflow-support/functions"

process toBCLConvertStyle
{
    input:
        tuple val(unitId), val(read), path(readFastq), path(umiFastq)
        
    output:
        tuple val(unitId), path(combinedFastq)
        
    shell:
        combinedFastq = "${safeName(unitId)}.bclconvert.r_${read}.fq.gz"
        
        template 'preprocessing/umiIntoHeader.sh'
}
