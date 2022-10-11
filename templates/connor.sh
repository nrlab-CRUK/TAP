#!/bin/bash

set -ou pipefail

# Connor fails if there are zero reads.

AT_LEAST_ONE=$(samtools view "!{bam}" | head -n 1 | wc -l)

if [[ $AT_LEAST_ONE -gt 0 ]]
then
    connor -v --force \
        --min_family_size_threshold !{params.CONNOR_MIN_FAMILY_SIZE_THRESHOLD} \
        --consensus_freq_threshold !{params.CONNOR_CONSENSUS_FREQ_THRESHOLD} \
        --umt_distance_threshold !{params.CONNOR_UMT_DISTANCE_THRESHOLD} \
        --umt_length !{params.CONNOR_UMT_LENGTH} \
        --log_file .command.out \
        "!{bam}" \
        "!{connorFile}"
else
    # Make the original file the output file.
    echo "!{bam} has no reads."
    ln "!{bam}" "!{connorFile}"
fi
