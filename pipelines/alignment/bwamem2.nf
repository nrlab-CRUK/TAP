/*
 * BWAmem2 paired end pipeline inner work flow.
 */

include { safeName } from "../../modules/nextflow-support/functions"
include { bwamem2Index } from '../../functions/references'

/*
 * Align with BWAmem2.
 */
process bwamem2
{
    cpus 4
    memory { 20.GB + 4.GB * task.attempt }
    time { 8.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(unitId), val(chunk), path(read1), path(read2), path(bwamem2IndexDir), val(bwamem2IndexPrefix)

    output:
        tuple val(unitId), val(chunk), path(outBam)

    shell:
        outBam = "${safeName(unitId)}.c_${chunk}.bam"
        template "alignment/bwamem2.sh"
}


/*
 * BWAMEM2 alignment.
 *
 * In: the FASTQ channel (unitId, chunk, read1, read2)
 * In: the CSV channel (unitId, row)
 *
 * Out: BAM channel (unitId, chunk, bam) - note no index
 */
workflow bwamem2WF
{
    take:
        fastqChannel

    main:
        bwamem2IndexPath = file(bwamem2Index())
        bwamem2IndexChannel = channel.of(tuple bwamem2IndexPath.parent, bwamem2IndexPath.name)

        // Cannot do "each tuple" in the inputs to bwamem2 process.
        // See https://github.com/nextflow-io/nextflow/issues/1531
        alignmentChannel = fastqChannel.combine(bwamem2IndexChannel)

        // The alignment itself.
        bwamem2(alignmentChannel)

    emit:
        bamChannel = bwamem2.out
}
