#!/bin/bash

set -ou pipefail
set +e  # Don't fail on error

bwa-mem2 mem \
    !{params.BWAMEM2_OPTIONS} \
    -t !{task.cpus} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    "!{read1}" \
    "!{read2}" | \
samtools view \
    -b -h -o "!{outBam}"

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    "!{read1}" \
    "!{read2}"
