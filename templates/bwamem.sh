#!/bin/bash

set -eou pipefail

bwa-mem2 mem \
    -t !{task.cpus} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    !{sequenceFiles} | \
samtools view \
    -b -h -o "!{outBam}"
