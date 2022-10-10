include { picard_buildbamindex } from '../processes/picard'

process connor
{
    memory = { 8.GB * task.attempt }
    time = { 8.hour + 16.hour * (task.attempt - 1) }
    maxRetries = 2

    input:
        tuple val(sampleId), path(bam), path(index)

    output:
        tuple val(sampleId), path(connorFile)

    shell:
        connorFile = "${sampleId}.connor.bam"

        template "connor.sh"
}

workflow connorWF
{
    take:
        alignedChannel

    main:
        decision = alignedChannel.branch
        {
            connor : params.CONNOR_COLLAPSING
            noConnor : true
        }

        connor(decision.connor) | picard_buildbamindex

        collapsedChannel = decision.noConnor.mix(picard_buildbamindex.out)

    emit:
        collapsedChannel
}
