process baseCallRecalibrate
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFasta), path(referenceFastaIndex), path(referenceFastaDictionary), path(knownSites), path(knownSitesIndexes)

    output:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFasta), path(referenceFastaIndex), path(referenceFastaDictionary), path(recalibrationTable)

    shell:
        recalibrationTable = "${sampleId}.recalibrated.table"

        template "gatk/BaseRecalibrator.sh"
}

process recalibrateReads
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(referenceFasta), path(referenceFastaIndex), path(referenceFastaDictionary), path(recalibrationTable)

    output:
        tuple val(sampleId), path(outBam), path(outBai)

    shell:
        outBam = "${sampleId}.recalibrated.bam"
        outBai = "${sampleId}.recalibrated.bai"

        template "gatk/ApplyBQSR.sh"
}

workflow gatk
{
    take:
        alignmentChannel

    main:
        referenceFasta = channel.fromPath("${params.REFERENCE_FASTA}", checkIfExists: true)
        referenceFastaIndex = channel.fromPath("${params.REFERENCE_FASTA}.fai", checkIfExists: true)
        referenceFastaExtension = file("${params.REFERENCE_FASTA}").extension
        referenceFastaDictionary = channel.fromPath("${params.REFERENCE_FASTA}".replaceFirst("${referenceFastaExtension}\$", "dict"), checkIfExists: true)
        referenceFasta = referenceFasta.combine(referenceFastaIndex).combine(referenceFastaDictionary)

        // note that channel.fromPath results in an error for the default GATK_KNOWN_SITES
        // empty list setting - we shouldn't need to set this if not actually running BQSR
        // hence the use of channel.from and a map function to check the file(s) specify
        // exist
        knownSites = channel.from(params.GATK_KNOWN_SITES).map { f -> file(f, checkIfExists: true)}.collect()
        knownSitesIndexes = channel.from(params.GATK_KNOWN_SITES).map { f -> file("${f}.*", checkIfExists: true)}.collect()

        decision = alignmentChannel.branch
        {
            gatk : params.GATK_BQSR
            asIs : true
        }

        recalibratedChannel = decision.gatk
            .combine(referenceFasta)
            .combine(knownSites.toList())
            .combine(knownSitesIndexes.toList())
            | baseCallRecalibrate
            | recalibrateReads
            | mix(decision.asIs)

    emit:
        recalibratedChannel
}
