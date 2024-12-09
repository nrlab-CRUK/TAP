#!/bin/bash

set -u
set +e

python3 "!{projectDir}/python/KapaTrim.py" \
    --spacer=!{spacerLength} \
    --read1="!{read1In}" --read2="!{read2In}" \
    --out1="!{read1Out}" --out2="!{read2Out}"

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    !{read1In} \
    !{read2In}
