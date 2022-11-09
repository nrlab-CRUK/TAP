include { safeName } from '../functions/functions'
include { referenceFasta; gatkKnownSites } from '../functions/references'

process baseCallRecalibrate
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFastaFile), path(referenceFastaIndex), path(referenceFastaDictionary), path(knownSites), path(knownSitesIndexes)

    output:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFastaFile), path(referenceFastaIndex), path(referenceFastaDictionary), path(recalibrationTable)

    shell:
        recalibrationTable = "${safeName(sampleId)}.recalibrated.table"

        template "gatk/BaseRecalibrator.sh"
}

process recalibrateReads
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFastaFile), path(referenceFastaIndex), path(referenceFastaDictionary), path(recalibrationTable)

    output:
        tuple val(sampleId), path(outBam), path(outBai)

    shell:
        outBam = "${safeName(sampleId)}.recalibrated.bam"
        outBai = "${safeName(sampleId)}.recalibrated.bai"

        template "gatk/ApplyBQSR.sh"
}

workflow gatk
{
    take:
        alignmentChannel

    main:
        referenceFastaFile = channel.fromPath(referenceFasta(), checkIfExists: true)
        referenceFastaIndex = channel.fromPath("${referenceFasta()}.fai", checkIfExists: true)
        referenceFastaExtension = file(referenceFasta()).extension
        referenceFastaDictionary = channel.fromPath(referenceFasta().replaceFirst("${referenceFastaExtension}\$", "dict"), checkIfExists: true)
        referenceFastaChannel = referenceFastaFile.combine(referenceFastaIndex).combine(referenceFastaDictionary)

        // note that channel.fromPath results in an error for the default GATK_KNOWN_SITES
        // empty list setting - we shouldn't need to set this if not actually running BQSR
        // hence the use of channel.from and a map function to check the file(s) specify
        // exist
        knownSites = channel.from(gatkKnownSites()).map { f -> file(f, checkIfExists: true)}.collect()
        knownSitesIndexes = channel.from(gatkKnownSites()).map { f -> file("${f}.*", checkIfExists: true)}.collect()

        decision = alignmentChannel.branch
        {
            gatk : params.GATK_BQSR
            asIs : true
        }

        recalibratedChannel = decision.gatk
            .combine(referenceFastaChannel)
            .combine(knownSites.toList())
            .combine(knownSitesIndexes.toList())
            | baseCallRecalibrate
            | recalibrateReads
            | mix(decision.asIs)

    emit:
        recalibratedChannel
}
