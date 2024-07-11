/*
 * Generic FASTQ processes.
 */

include { safeName } from "../modules/nextflow-support/functions"

 /*
  * Extract the chunk number from a file produced by splitFastq. It is the
  * six digits just before the .fq or .fq.gz suffix.
  */
 def extractChunkNumber(f)
 {
     def m = f.name =~ /.+-C(\d{6})\.fq(\.gz)?$/
     assert m : "Don't have file pattern with chunk numbers: '${f.name}'"
     return Integer.parseInt(m[0][1], 10)
 }

/*
 * Split FASTQ file into chunks.
 */
process splitFastq
{
    memory { 128.MB * task.attempt }
    time { 12.hour * task.attempt}
    maxRetries 2

    input:
        tuple val(unitId), val(read), path(fastqFiles, arity: '1..*')

    output:
        // Note: glob file name can return a list of files or a single file, not a list of one file.
        // See https://github.com/nextflow-io/nextflow/issues/2425

        tuple val(unitId), val(read), path("*-C??????.fq.gz")

    shell:
        sourceFile = fastqFiles[0]
        umiFile = fastqFiles.size() > 1 ? fastqFiles[1] : null
        umiArg = umiFile ? "--umi=\"${umiFile}\"" : ''
        nameBase = "${safeName(unitId)}.r_${read}"

        template "fastq/splitFastq.sh"
}
