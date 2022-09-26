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
    memory 8.MB
    time { 4.hour * task.attempt}
    maxRetries 1

    input:
        tuple val(sampleId), val(read), path(fastqFile)

    output:
        // Note: glob file name can return a list of files or a single file, not a list of one file.
        // See https://github.com/nextflow-io/nextflow/issues/2425

        tuple val(sampleId), val(read), path("*-S??????.fq.gz")

    shell:
        template "fastq/splitFastq.sh"
}
