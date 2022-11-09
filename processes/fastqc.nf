include { safeName } from '../functions/functions'

process fastqc
{
    memory 300.MB
    time   4.hour

    publishDir params.REPORTS_DIR, mode: 'link', pattern: '*.html'

    when: params.FASTQC

    input:
        tuple val(sampleId), path(bamFile), path(bamIndex)

    output:
        path("${safeSampleId}_fastqc.html"), emit: reportChannel

    shell:
        safeSampleId = safeName(sampleId)
        canonicalBam = "${safeSampleId}.bam"

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
