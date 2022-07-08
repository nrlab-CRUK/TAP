/*
 * Trimming processes.
 */

def baseName(fastqFile)
{
    def name = fastqFile.name
    name = name.replaceAll(/\.(fq|fastq)(\.gz)?$/, "")
    name = name.replaceAll(/\.r_\d$/, "")
    return name
}

process trimGalore
{
    cpus   16
    memory '1G'

    input:
        tuple val(sampleId), val(indexType), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), val(indexType), path("${fileBase}_val_1.fq.gz"), path("${fileBase}_val_2.fq.gz"), path(umiread)

    shell:
        fileBase = baseName(read1)

        template "trimming/trimGalore.sh"
}

process tagtrim
{
    cpus   1
    memory '256M'

    input:
        tuple val(sampleId), val(indexType), path(read1In), path(read2In), path(noUmiRead)

    output:
        tuple val(sampleId), val(indexType), path(read1Out), path(read2Out), path(umi1Out), path(umi2Out)

    shell:
        fileBase = baseName(read1In)
        read1Out = "${fileBase}.r_1.tagtrim.fq.gz"
        read2Out = "${fileBase}.r_2.tagtrim.fq.gz"
        umi1Out = "${fileBase}.u_1.tagtrim.fq.gz"
        umi2Out = "${fileBase}.u_2.tagtrim.fq.gz"

        template "trimming/tagtrim.sh"
}
