/*
 * Miscellaneous helper functions used all over the pipeline.
 */

@Grab('org.apache.commons:commons-lang3:3.12.0')

import static org.apache.commons.lang3.CharUtils.isAsciiAlphanumeric

import java.text.*

/**
 * Give a number for the Java heap size based on the task memory, allowing for
 * some overhead for the JVM itself from the total allowed.
 */
def javaMemMB(task)
{
    return task.memory.toMega() - 128
}

/**
 * Get the size of a collection of things. It might be that the thing
 * passed in isn't a collection or map, in which case the size is 1.
 *
 * See https://github.com/nextflow-io/nextflow/issues/2425
 */
def sizeOf(thing)
{
    return (thing instanceof Collection || thing instanceof Map) ? thing.size() : 1
}

/**
 * Create the unit identifier from the UNIT_ID_PARTS and UNIT_ID_SEPARATOR
 * parameters for a given row from the driving CSV file.
 */
def unitIdGenerator(params, row)
{
    return params.UNIT_ID_PARTS.collect { row[it] }.join(params.UNIT_ID_SEPARATOR)
}

/**
 * Make a name safe to be used as a file name. Everything that's not
 * alphanumeric, dot, underscore or hyphen is converted to an underscore.
 * Spaces are just removed.
 */
def safeName(name)
{
    def nameStr = name.toString()
    def safe = new StringBuilder(nameStr.length())
    def iter = new StringCharacterIterator(nameStr)

    for (def c = iter.first(); c != CharacterIterator.DONE; c = iter.next())
    {
        switch (c)
        {
            case { isAsciiAlphanumeric(it) }:
            case '_':
            case '-':
            case '.':
                safe << c
                break

            case ' ':
            case '\t':
                // Add nothing.
                break

            default:
                safe << '_'
                break
        }
    }

    return safe.toString()
}
