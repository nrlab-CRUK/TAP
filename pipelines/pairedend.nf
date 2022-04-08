/*
 * Post alignment work flow for paired end alignment.
 * The input to this work flow should be the aligned BAM files from the aligner work flow.
 */

include {
    picard_fixmate; picard_merge_or_markduplicates; picard_addreadgroups
} from "../processes/picard"

workflow pairedend
{
    take:
        alignment_channel
        sequencing_info_channel

    main:
        reference_fasta_channel = channel.fromPath(params.REFERENCE_FASTA, checkIfExists: true)

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            alignment_channel
            .combine(sequencing_info_channel.map { tuple it.PlatformUnit, it }, by: 0)

        picard_addreadgroups(read_groups_channel) | picard_fixmate

        // Group the outputs by base name.
        picard_merge_or_markduplicates(picard_fixmate.out.groupTuple())
}
