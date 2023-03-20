/*
 * BWA-meth paired end pipeline inner work flow.
 */

include { safeName } from "../../modules/nextflow-support/functions"
include { bwamethIndex } from '../../functions/references'

/*
 * Align with bwa-meth.
 */
process bwameth
{
    cpus 4
    memory { 20.GB + 4.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(unitId), val(chunk), path(read1), path(read2), path(bwamethIndexDir), val(bwamethIndexPrefix)

    output:
        tuple val(unitId), val(chunk), path(outBam)

    shell:
        outBam = "${safeName(unitId)}.c_${chunk}.bam"
        template "alignment/bwameth.sh"
}


/*
 * bwa-meth alignment.
 *
 * In: the FASTQ channel (unitId, chunk, read1, read2)
 * In: the CSV channel (unitId, row)
 *
 * Out: BAM channel (unitId, chunk, bam) - note no index
 */
workflow bwamethWF
{
    take:
        fastqChannel

    main:
        bwamethIndexPath = file(bwamethIndex())
        bwamethIndexChannel = channel.of(tuple bwamethIndexPath.parent, bwamethIndexPath.name)

        alignmentChannel = fastqChannel.combine(bwamethIndexChannel)

        bwameth(alignmentChannel)

    emit:
        bamChannel = bwameth.out
}
