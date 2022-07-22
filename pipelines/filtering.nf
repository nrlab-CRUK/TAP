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
        blacklistRefChannel = params.BLACKLIST ? channel.fromPath(params.BLACKLIST) : channel.empty

        noIndexAlignmentChannel = alignmentChannel.map { s, b, i -> tuple s, b }

        filterReads(noIndexAlignmentChannel)

        blacklistOrNo = filterReads.out.branch
        {
            blacklist : params.BLACKLIST
            no : true
        }

        filterBlacklist(blacklistOrNo.blacklist, blacklistRefChannel)

        afterBlacklisting = blacklistOrNo.no.mix(filterBlacklist.out)

        picard_buildbamindex(afterBlacklisting)

    emit:
        picard_buildbamindex.out
}
