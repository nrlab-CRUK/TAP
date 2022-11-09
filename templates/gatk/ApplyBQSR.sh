#!/usr/bin/bash

set -e

gatk ApplyBQSR \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    --bqsr-recal-file "!{recalibrationTable}" \
    --output "!{outBam}"
