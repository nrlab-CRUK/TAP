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
        // Note: glob file name can return a list of files or a single file, not a list of one file.
        // See https://github.com/nextflow-io/nextflow/issues/2425

        tuple val(sampleId), val(read), path("*-S??????.fq.gz")

    shell:
        template "fastq/splitFastq.sh"
}

process prependSingleUMI
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

        """
        seqkit concat -w 0 "!{umiread}" "!{read1}" -o "!{read1out}"
        seqkit concat -w 0 "!{umiread}" "!{read2}" -o "!{read2out}"
        """
}

process prependDoubleUMI
{
    /*
     * Can optimise this later to do each read as a separate process.
     */

    input:
        tuple val(sampleId), path(read1), path(read2), path(umi1), path(umi2)

    output:
        tuple val(sampleId), path(read1out), path(read2out)

    shell:
        read1out = "${sampleId}.umi.r_1.fq.gz"
        read2out = "${sampleId}.umi.r_2.fq.gz"

        """
        seqkit concat -w 0 "!{umi1}" "!{read1}" -o "!{read1out}"
        seqkit concat -w 0 "!{umi2}" "!{read2}" -o "!{read2out}"
        """
}
