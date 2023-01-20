/*
 * Miscellaneous helper functions used all over the pipeline.
 */

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
