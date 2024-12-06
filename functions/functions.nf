/*
 * Miscellaneous helper functions used all over the pipeline.
 */

import org.apache.commons.compress.compressors.CompressorException
import org.apache.commons.compress.compressors.CompressorStreamFactory

/**
 * Create the unit identifier from the UNIT_ID_PARTS and UNIT_ID_SEPARATOR
 * parameters for a given row from the driving CSV file.
 */
def unitIdGenerator(params, row)
{
    return params.UNIT_ID_PARTS.collect { row[it] }.join(params.UNIT_ID_SEPARATOR)
}

/**
 * Create the sample identifier from the SAMPLE_ID_PARTS and SAMPLE_ID_SEPARATOR
 * parameters for a given row from the driving CSV file.
 */
def sampleIdGenerator(params, row)
{
    return params.SAMPLE_ID_PARTS.collect { row[it].replaceAll(/\s+/, '') }.join(params.SAMPLE_ID_SEPARATOR)
}

/**
 * Detect whether or not the reads in the given FASTQ file have UMIs.
 * This is looking for BCL Convert style UMIs in the read names.
 */
def hasUMIs(fastqFile)
{
    def factory = new CompressorStreamFactory()

    return fastqFile.withInputStream
    {
        baseStream ->
        def stream = baseStream
        try
        {
            stream = factory.createCompressorInputStream(baseStream)
        }
        catch (CompressorException e)
        {
            // Not a compressed stream.
        }

        def reader = new InputStreamReader(stream, 'UTF-8')

        def firstRead = reader.readLine()
        def hasUMI = false

        if (firstRead)
        {
            def parts = firstRead.split(/[\s:]+/)
            hasUMI = parts.length >= 8 && parts[7] ==~ /r?[ACGT]+(\+r?[ACGT]+)?/
        }

        return hasUMI
    }
}
