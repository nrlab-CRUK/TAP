#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#BuildBamIndex
#
# Generates a BAM index ".bai" file. This tool creates an index file for the input BAM that allows
# fast look-up of data in a BAM file, like an index on a database. Note that this tool cannot be
# run on SAM files, and that the input BAM file must be sorted in coordinate order.

export TMPDIR=temp
mkdir -p "$TMPDIR"

function clean_up
{
    rm -rf "$TMPDIR"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

picard -Djava.io.tmpdir="$TMPDIR" \
-Xms!{javaMem}m -Xmx!{javaMem}m \
BuildBamIndex \
INPUT="!{inBam}" \
OUTPUT="!{outBai}" \
MAX_RECORDS_IN_RAM=!{readsInRam} \
COMPRESSION_LEVEL=1 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
