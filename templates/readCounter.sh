#!/bin/bash

# Insists that the index is *.bam.bai, not *.bai.

if [ ! -e "!{bamIndex}" ]
then
    cp -d "!{inBai}" "!{bamIndex}"
fi

readCounter \
    --window !{params.READ_COUNTER_BIN_SIZE} --quality 20 \
    -c "!{chromosomes.join(',')}" \
    "!{inBam}" > "!{wiggleFile}"
