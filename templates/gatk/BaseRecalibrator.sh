#!/usr/bin/bash

set -u

gatk BaseRecalibrator \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    !{knownSites.collect { "--known-sites \"" + it + "\" " }.join()} \
    --output "!{recalibrationTable}"
