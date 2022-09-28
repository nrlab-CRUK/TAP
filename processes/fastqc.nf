process fastqc
{
    memory '300m'
    time   '4h'
    cpus   1

    publishDir "${launchDir}/reports", mode: 'link', pattern: '*.html'

    when: params.FASTQC

    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)

    output:
        path("${sampleId}_fastqc.html"), emit: reportChannel

    shell:
        canonicalBam = "${sampleId}.bam"

        """
        mkdir temp

        if [ "!{bamFile}" != "!{canonicalBam}" ]
        then
            ln "!{bamFile}" "!{canonicalBam}"
        fi

        fastqc \
            --threads !{task.cpus} \
            --dir temp \
            --extract \
            "!{canonicalBam}"

        rm -rf temp
        """
}
