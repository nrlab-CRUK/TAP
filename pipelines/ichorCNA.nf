include { picard_buildbamindex } from '../processes/picard'

/**
 * Test whether ichorCNA can be run.
 * It must be turned on and the assembly a recognised one.
 */
def canRunIchorCNA(params)
{
    def assembly = params.ASSEMBLY
    def doingIchor = params.ICHORCNA

    switch (assembly)
    {
        case 'hg19':
        case 'hg38':
            // Ok.
            break

        default:
            if (doingIchor)
            {
                log.warn("Assembly ${assembly} isn't one that can be used with IchorCNA.")
            }
            doingIchor = false
            break
    }

    return doingIchor
}

/**
 * Set the files used for IchorCNA based on the genome selected.
 */
def setIchorParameters(params)
{
    def assembly = params.ASSEMBLY
    def doingIchor = params.ICHORCNA

    def ichorParams = [:]

    switch (assembly)
    {
        case 'hg19':
            ichorParams['ICHORCNA_NORMAL_PANEL'] = 'HD_ULP_PoN_1Mb_median_normAutosome_mapScoreFiltered_median.rds'
            ichorParams['ICHORCNA_GC_WIGGLE'] = 'gc_hg19_1000kb.wig'
            ichorParams['ICHORCNA_MAP_WIGGLE'] = 'map_hg19_1000kb.wig'
            ichorParams['ICHORCNA_CENTROMERE'] = 'GRCh37.p13_centromere_UCSC-gapTable.txt'
            break

        case 'hg38':
            ichorParams['ICHORCNA_NORMAL_PANEL'] = 'HD_ULP_PoN_hg38_1Mb_median_normAutosome_median.rds'
            ichorParams['ICHORCNA_GC_WIGGLE'] = 'gc_hg38_1000kb.wig'
            ichorParams['ICHORCNA_MAP_WIGGLE'] = 'map_hg38_1000kb.wig'
            ichorParams['ICHORCNA_CENTROMERE'] = 'GRCh38.GCA_000001405.2_centromere_acen.txt'
            break
    }

    return ichorParams
}

process readCounter
{
    time '1h'
    memory '256m'

    when:
        canRunIchorCNA(params)

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

    output:
        tuple val(sampleId), path("*.pdf")

    shell:
        ichorParams = setIchorParameters(params)

        template "ichorcna.sh"
}

workflow ichorCNAWF
{
    take:
        alignedChannel

    main:
        canonicalChromosomesChannel = channel.fromPath(params.CANONICAL_CHROMOSOMES, checkIfExists: true)

        readCounter(alignedChannel, canonicalChromosomesChannel) | ichorCNA
}
