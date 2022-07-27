#!/bin/bash

set -eou pipefail

bwa-mem2 mem \
    -t !{Math.max(1, task.cpus - 1)} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    !{sequenceFiles} | \
samtools view \
    -b -h -o "!{outBam}"
