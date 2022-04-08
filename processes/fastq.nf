/*
 * Generic FASTQ processes.
 */

process trimFASTQ
{
    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path("${read1.baseName}*.fastq.gz"), path("${read2.baseName}*.fastq.gz"), path(umiread)

    shell:
        template "trim.sh"
}

process prependUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    input:
        tuple val(sampleId), path(read1), path(read2), path(umiread)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        template "prependUMI.sh"
}

 /*
  * Extract the chunk number from a file produced by splitFastq. It is the
  * six digits just before the .fq or .fq.gz suffix.
  */
 def extractChunkNumber(f)
 {
     def m = f.name =~ /.+-S(\d{6})\.fq(\.gz)?$/
     assert m : "Don't have file pattern with chunk numbers: '${f.name}'"
     return m[0][1]
 }

/*
 * Split FASTQ file into chunks.
 */
process splitFastq
{
    cpus 1
    memory '8MB'

    input:
        tuple val(sampleId), val(read), path(fastqFile)

    output:
        tuple val(sampleId), val(read), path("*-S??????.fq.gz")

    shell:
        """
        splitfastq -n 1000000 -p "!{sampleId}.r_!{read}" "!{fastqFile}"
        """
}
