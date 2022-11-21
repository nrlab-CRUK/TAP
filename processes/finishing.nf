include { safeName } from '../functions/functions'

process publish
{
    executor 'local'
    memory   '1m'
    time     '2m'

    stageInMode 'link'
    publishDir params.ALIGNED_DIR, mode: 'link'

    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)

    output:
        tuple val(sampleId), path(finalBam), path(finalIndex)

    shell:
        safeSampleId = safeName(sampleId)
        finalBam = "${safeSampleId}.bam"
        finalIndex = "${safeSampleId}.bai"

        """
            if [ "!{bamFile}" != "!{finalBam}" ]
            then
                ln "!{bamFile}" "!{finalBam}"
                ln "!{bamIndex}" "!{finalIndex}"
            fi
        """
}

process checksum
{
    publishDir params.ALIGNED_DIR, mode: 'copy'

    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)

    output:
        tuple val(sampleId), path(checksumFile)

    shell:
        safeSampleId = safeName(sampleId)
        checksumFile = "${safeSampleId}.md5sums.txt"

        """
        md5sum "!{bamFile}" "!{bamIndex}" > "!{checksumFile}"
        """
}
