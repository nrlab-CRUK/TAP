#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#SortSam
#
# Sorts a SAM or BAM file.  This tool sorts the input SAM or BAM file by coordinate,
# queryname (QNAME), or some other property of the SAM record. The SortOrder of a
# SAM/BAM file is found in the SAM file header tag @HD in the field labeled SO.
#
# For a coordinate sorted SAM/BAM file, read alignments are sorted first by the
# reference sequence name (RNAME) field using the reference sequence dictionary (@SQ tag).
# Alignments within these subgroups are secondarily sorted using the left-most mapping
# position of the read (POS).  Subsequent to this sorting scheme, alignments are listed
# arbitrarily.
#
# For queryname-sorted alignments, all alignments are grouped using the queryname field
# but the alignments are not necessarily sorted within these groups.  Reads having the
# same queryname are derived from the same template.

# See http://broadinstitute.github.io/picard/faq.html question 2 for notes
# on the RAM and maxRecordsInRAM balance.


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
SortSam \
INPUT="!{inBam}" \
OUTPUT="!{outBam}" \
SORT_ORDER=coordinate \
MAX_RECORDS_IN_RAM=!{readsInRam} \
CREATE_INDEX=true \
COMPRESSION_LEVEL=1 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
