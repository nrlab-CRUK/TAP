include { picard_buildbamindex } from '../processes/picard'

process byBaseQuality
{
    time '1h'
    memory '256m'

    input:
        tuple val(sampleId), path(inBam), path(inBai)

    output:
        tuple val(sampleId), path(outBam)

    shell:
        outBam = "${sampleId}.selected.bam"

        """
        python3 "${projectDir}/python/read_selection_tools.py" \
            bqual \
            "!{inBam}" \
            "!{outBam}" \
            --bqual_mean_min !{params.BASE_QUALITY_MEAN_MINIMUM} \
            --bqual_first_bases !{params.BASE_QUALITY_FIRST_BASES} \
            --bqual_last_bases !{params.BASE_QUALITY_LAST_BASES}
        """
}

process byLength
{
    time '1h'
    memory '256m'

    input:
        tuple val(sampleId), path(inBam), path(inBai)

    output:
        tuple val(sampleId), path(outBam)

    shell:
        outBam = "${sampleId}.selected.bam"

        """
        python3 "${projectDir}/python/read_selection_tools.py" \
            length \
            "!{inBam}" \
            "!{outBam}" \
            --template_min !{params.TEMPLATE_MINIMUM} \
            --template_max !{params.TEMPLATE_MAXIMUM}
        """
}

workflow readSelectionWF
{
    take:
        alignedChannel

    main:
        decision = alignedChannel.branch
        {
            bqual: params.READ_SELECTION?.toLowerCase() in [ 'basequality', 'quality', 'bqual' ]
            length: params.READ_SELECTION?.toLowerCase() in [ 'length', 'size', 'insert' ]
            none : true
        }

        byBaseQuality(decision.bqual)
        byLength(decision.length)

        selectedChannel = byBaseQuality.out.mix(byLength.out)

        picard_buildbamindex(selectedChannel)

        allChannel = decision.none.mix(picard_buildbamindex.out)

    emit:
        allChannel
}
