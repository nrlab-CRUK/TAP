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
 
process trimFASTQ
{
    cpus   16
    memory '1G'
    
    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path("${fileBase}_val_1.fq.gz"), path("${fileBase}_val_2.fq.gz"), path(umiread)

    shell:
        fileBase = baseName(read1)
        
        template "trimming/trimGalore.sh"
}
