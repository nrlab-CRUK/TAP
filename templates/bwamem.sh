#!/bin/bash

set -eou pipefail

bwa-mem2 mem \
    -t !{task.cpus} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    "!{read1}" \
    "!{read2}" | \
samtools view \
    -b -h -o "!{outBam}"
