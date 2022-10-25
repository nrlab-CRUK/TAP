#!/bin/bash

splitfastq -n !{params.CHUNK_SIZE} -p "!{nameBase}" "!{fastqFile}"

# Need to see if anything was produced. If the input file has no reads,
# splitfastq doesn't give any output. To make things easier we'll create
# a single empty file as the split.

firstFile="!{nameBase}-S000001.fq.gz"

if ! [ -e $firstFile ]
then
    echo "!{fastqFile} seems to be empty." 1>&2
    echo "H4sIAAAAAAAAAAMAAAAAAAAAAAA=" | base64 -d > $firstFile
fi
