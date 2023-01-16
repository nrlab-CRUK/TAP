#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#MergeSamFiles
#
# Merges multiple SAM and/or BAM files into a single file.  This tool is used for combining
# SAM and/or BAM files from different runs or read groups, similarly to the "merge" function
# of Samtools (http://www.htslib.org/doc/samtools.html).
#
# Note that to prevent errors in downstream processing, it is critical to identify/label read
# groups appropriately. If different samples contain identical read group IDs, this tool will
# avoid collisions by modifying the read group IDs to be unique. For more information about
# read groups, see the GATK Dictionary entry. (https://www.broadinstitute.org/gatk/guide/article?id=6472)


export TMPDIR=temp
mkdir -p "$TMPDIR"

function clean_up
{
    groovy "!{projectDir}/groovy/removeInput.groovy" !{params.EAGER_CLEANUP} $1 !{inBams}

    rm -rf "$TMPDIR"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

picard -Djava.io.tmpdir="$TMPDIR" \
-Xms!{javaMem}m -Xmx!{javaMem}m \
MergeSamFiles \
!{'INPUT=' + inBams.join(' INPUT=')} \
OUTPUT="!{outBam}" \
ASSUME_SORTED=true \
MAX_RECORDS_IN_RAM=!{readsInRam} \
CREATE_INDEX=true \
COMPRESSION_LEVEL=5 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

groovy "!{projectDir}/groovy/outOfMemoryCheck.groovy" $?

clean_up $?
