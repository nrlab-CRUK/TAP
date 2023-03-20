#!/bin/bash

set -ou pipefail
set +e  # Don't fail on error

bwameth.py \
    !{params.BWAMETH_OPTIONS} \
    --threads !{task.cpus} \
    --reference "!{bwamethIndexDir}/!{bwamethIndexPrefix}" \
    "!{read1}" \
    "!{read2}" | \
samtools view \
    -b -h -o "!{outBam}"

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    "!{read1}" \
    "!{read2}"
