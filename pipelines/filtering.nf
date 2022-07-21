include { picard_buildbamindex } from '../processes/picard'

process filterReads
{
    input:
        tuple val(sampleId), path(inBam)

    output:
        tuple val(sampleId), path(outBam)

    shell:
        outBam = "${sampleId}.simplefiltered.bam"

        """
        samtools view -h -q !{params.MINIMUM_MAPPING_QUALITY} -F !{params.SAM_EXCLUDE_FLAGS} \
            !{inBam} -bo ${outBam}
        """
}

process filterBlacklist
{
    input:
        tuple val(sampleId), path(inBam)
        each path(blacklistFile)

    output:
        tuple val(sampleId), path(outBam)

    shell:
        outBam = "${sampleId}.filtered.bam"

        """
        bedtools intersect -v -abam !{inBam} -b !{blacklistFile} > !{outBam}
        """
}

workflow filtering
{
    take:
        alignmentChannel

    main:
        blacklistChannel = channel.fromPath(params.BLACKLIST)

        noIndexAlignmentChannel = alignmentChannel.map { s, b, i -> tuple s, b }

        filterReads(noIndexAlignmentChannel)
        filterBlacklist(filterReads.out, blacklistChannel)
        picard_buildbamindex(filterBlacklist.out)

    emit:
        picard_buildbamindex.out
}
