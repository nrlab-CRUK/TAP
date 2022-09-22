include { picard_buildbamindex } from '../processes/picard'

process filterReads
{
    input:
        tuple val(sampleId), path(inBam), path(inBai)

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
        blacklistRefChannel = params.BLACKLIST ? channel.fromPath("${params.BLACKLIST}", checkIfExists: true) : channel.empty()

        decision = alignmentChannel.branch
        {
            filter: params.FILTER
            asIs:   true
        }

        filterReads(decision.filter)

        blacklistOrNo = filterReads.out.branch
        {
            blacklist : params.BLACKLIST
            no : true
        }

        filterBlacklist(blacklistOrNo.blacklist, blacklistRefChannel)

        afterBlacklistingChannel = blacklistOrNo.no.mix(filterBlacklist.out)

        picard_buildbamindex(afterBlacklistingChannel)

        afterFilteringChannel = decision.asIs.mix(picard_buildbamindex.out)

    emit:
        afterFilteringChannel
}
