#!/usr/bin/bash

set -eu

gatk BaseRecalibrator \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    !{knownSites.collect { "--known-sites \"" + it + "\" " }.join()} \
    --output "!{recalibrationTable}"
