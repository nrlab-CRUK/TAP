/*
 * Common post alignment work flow.
 */

include { addReadGroups; fixMateInformation } from "../../processes/picard"

/*
 * Post alignment processing. Set read groups and fix mate pairs.
 *
 * In: the aligned channel (unitId, chunk, bamFile)
 * In: the CSV channel (unitId, row)
 *
 * Out: BAM channel (unitId, bam) - note no index
 */
workflow postAlignment
{
    take:
        alignedChannel
        sampleInfoChannel

    main:
        // Add sequencing info back to the channel for read groups.
        // It is available from sampleInfoChannel, the rows from the CSV file.
        readGroupsChannel = alignedChannel.combine(sampleInfoChannel, by: 0)

        addReadGroups(readGroupsChannel) | fixMateInformation

    emit:
        bamChannel = fixMateInformation.out
}
