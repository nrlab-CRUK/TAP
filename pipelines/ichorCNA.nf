include { picard_buildbamindex } from '../processes/picard'

process readCounter
{
    time '1h'
    memory '256m'

    when:
        params.ICHORCNA

    input:
        tuple val(sampleId), path(inBam), path(inBai)
        each path(canonicalChromosomes)

    output:
        tuple val(sampleId), path(wiggleFile)

    shell:
        bamIndex = "${inBam}.bai"
        wiggleFile = "${sampleId}.wig"

        chromosomes = canonicalChromosomes.toRealPath().readLines()

        template "readCounter.sh"
}

process ichorCNA
{
    time '1h'
    memory '4G'

    publishDir 'ichorCNA', mode: 'link'

    input:
        tuple val(sampleId), path(wiggleFile)
        each path(gcWiggle)
        each path(mapWiggle)
        each path(centromere)
        each path(normalPanel)

    output:
        tuple val(sampleId), path("*.pdf")

    shell:
        template "ichorcna.sh"
}

workflow ichorCNAWF
{
    take:
        alignedChannel

    main:
        canonicalChromosomesChannel = channel.fromPath(params.CANONICAL_CHROMOSOMES, checkIfExists: true)
        gcWiggleChannel = channel.fromPath(params.ICHORCNA_GC_WIGGLE, checkIfExists: true)
        mapWiggleChannel = channel.fromPath(params.ICHORCNA_MAP_WIGGLE, checkIfExists: true)
        centromereChannel = channel.fromPath(params.ICHORCNA_CENTROMERE, checkIfExists: true)
        panelChannel = channel.fromPath(params.ICHORCNA_NORMAL_PANEL, checkIfExists: true)

        readCounter(alignedChannel, canonicalChromosomesChannel)
        ichorCNA(readCounter.out, gcWiggleChannel, mapWiggleChannel, centromereChannel, panelChannel)
}
