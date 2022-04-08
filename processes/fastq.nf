/*
 * Generic FASTQ processes.
 */

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
