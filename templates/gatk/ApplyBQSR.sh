#!/usr/bin/bash

set -e

gatk ApplyBQSR \
    --input "!{inBam}" \
    --reference "!{referenceFasta}" \
    --bqsr-recal-file "!{recalibrationTable}" \
    --output "!{outBam}"
