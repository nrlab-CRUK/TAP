#!/usr/bin/bash

set -eu

gatk ApplyBQSR \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    --bqsr-recal-file "!{recalibrationTable}" \
    --output "!{outBam}"

if [ "!{params.EAGER_CLEANUP}" == "true" -a $? -eq 0 ]
then
    groovy "!{projectDir}/groovy/removeInput.groovy" !{inBam}
fi
