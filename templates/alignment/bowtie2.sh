#!/bin/bash

set -ou pipefail
set +e  # Don't fail on error

bowtie2 \
    !{params.BOWTIE2_OPTIONS} \
    -p !{task.cpus} \
    -x "!{bowtie2IndexDir}/!{bowtie2IndexPrefix}" \
    -1 !{read1} \
    -2 !{read2} | \
samtools \
    view -b -h \
    -o "!{outBam}"

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    "!{read1}" \
    "!{read2}"
