#!/usr/bin/bash

set -e

gatk BaseRecalibrator \
    --input "!{inBam}" \
    --reference "!{referenceFasta}" \
    !{knownSites.collect { "--known-sites \"" + it + "\" " }.join()} \
    --output "!{recalibrationTable}"
