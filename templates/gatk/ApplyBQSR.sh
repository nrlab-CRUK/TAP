#!/usr/bin/bash

set -u
set +e

gatk ApplyBQSR \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    --bqsr-recal-file "!{recalibrationTable}" \
    --output "!{outBam}"

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? !{inBam}
