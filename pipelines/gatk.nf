include { javaMemMB } from '../processes/picard'

process createRealignerTargets
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai)
        val(fastaFile)
        val(knownSites)

    output:
        tuple val(sampleId), path(inBam), path(inBai), path(intervalsFile)

    shell:
        javaMem = javaMemMB(task)
        intervalsFile = "${sampleId}.intervals"

        template "gatk/RealignerTargetCreator.sh"
}

process indelRealign
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(intervalsFile)
        val(fastaFile)

    output:
        tuple val(sampleId), path(outBam), path(outBai), path(intervalsFile)

    shell:
        javaMem = javaMemMB(task)
        outBam = "${sampleId}.indelrealign.bam"
        outBai = "${sampleId}.indelrealign.bai"

        template "gatk/IndelRealigner.sh"
}

process baseCallRecalibrate
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(intervalsFile)
        val(fastaFile)

    output:
        tuple val(sampleId), path(inBam), path(inBai), path(tableFile)

    shell:
        javaMem = javaMemMB(task)
        tableFile = "${sampleId}.recalibrated.table"

        template "gatk/BaseRecalibrator.sh"
}

process recalibrateReads
{
    label 'gatk'

    input:
        tuple val(sampleId), path(inBam), path(inBai), path(tableFile)
        val(fastaFile)

    output:
        tuple val(sampleId), path(outBam), path(outBai)

    shell:
        javaMem = javaMemMB(task)
        outBam = "${sampleId}.recalibrated.bam"
        outBai = "${sampleId}.recalibrated.bai"

        template "gatk/PrintReads.sh"
}

workflow gatk
{
    take:
        alignmentChannel

    main:
        fastaChannel = channel.of(params.REFERENCE_FASTA)
        knownSitesChannel = channel.of(params.GATK_KNOWN_SITES)

        decision = alignmentChannel.branch
        {
            gatk : params.GATK_REALIGNMENT
            asIs : true
        }

        createRealignerTargets(decision.gatk, fastaChannel, knownSitesChannel)
        indelRealign(createRealignerTargets.out, fastaChannel)
        baseCallRecalibrate(indelRealign.out, fastaChannel)
        recalibrateReads(baseCallRecalibrate.out, fastaChannel)

        recalibratedChannel = decision.asIs.mix(recalibrateReads.out)

    emit:
        recalibratedChannel
}
