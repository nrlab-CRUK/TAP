process fastqc
{
    memory '300m'
    time   '4h'
    cpus   1

    publishDir "${launchDir}/reports", mode: 'link', pattern: '*.html'

    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)

    output:
        tuple val(sampleId), path(bamFile), path(bamIndex), emit: bamChannel
        path("${sampleId}_fastqc.html"), emit: reportChannel

    shell:
        canonicalBam = "${sampleId}.bam"

        """
        mkdir temp

        ln "!{bamFile}" "!{canonicalBam}"

        fastqc \
            --threads !{task.cpus} \
            --dir temp \
            --extract \
            "!{canonicalBam}"

        rm -rf temp
        """
}

workflow QC
{
    take:
        alignmentChannel

    main:
        decision = alignmentChannel.branch
        {
            fastqc: params.FASTQC
            skip: true
        }

        fastqc(decision.fastqc)

        afterQCChannel = decision.skip.mix(fastqc.out.bamChannel)

    emit:
        afterQCChannel
}