process connor
{
    time '1h'

    input:
        tuple val(sampleId), path(bam), path(bamIndex)

    output:
        tuple val(sampleId), path(connorFile)

    shell:
        connorFile = "${sampleId}.connor.bam"

        """
        connor -v --force \
            -s ${params.CONNOR_MIN_FAMILY_SIZE_THRESHOLD} \
            -f ${params.CONNOR_CONSENSUS_FREQ_THRESHOLD} \
            --umt_length ${params.CONNOR_UMT_LENGTH} \
            "!{bam}" \
            "!{connorFile}"
        """
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

        connor(decision.connor)

        collapsedChannel = decision.noConnor.mix(connor.out)

    emit:
        collapsedChannel
}
