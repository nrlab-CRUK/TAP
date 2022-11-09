#!/usr/bin/bash

set -e

gatk BaseRecalibrator \
    --input "!{inBam}" \
    --reference "!{referenceFastaFile}" \
    !{knownSites.collect { "--known-sites \"" + it + "\" " }.join()} \
    --output "!{recalibrationTable}"
