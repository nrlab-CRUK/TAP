include { safeName } from '../functions/functions'

process fastqc
{
    memory 300.MB
    time   4.hour

    publishDir "${launchDir}/reports", mode: 'link', pattern: '*.html'

    when: params.FASTQC

    input:
        tuple val(unitId), path(bamFile), path(bamIndex)

    output:
        path("${safeUnitId}_fastqc.html"), emit: reportChannel

    shell:
        safeUnitId = safeName(unitId)
        canonicalBam = "${safeUnitId}.bam"

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
