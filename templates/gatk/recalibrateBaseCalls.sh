#!/usr/bin/bash

set -e

# GATK3 requires Java 8. Does not work on Java 11.

!{params.JAVA8} \
    -Xms!{javaMem}m -Xmx!{javaMem}m \
    -jar "!{params.GATK_JAR}" \
    -T BaseRecalibrator \
    -R "!{fastaFile}" \
    -I "!{inBam}" \
    !{params.GATK_DBSNP ? '-knownSites "' + params.GATK_DBSNP + '"' : ''} \
    -knownSites "!{intervalsFile}" \
    -log .command.log \
    !{params.GATK_USE_INDEL_QUALITIES ? '' : "--disable_indel_quals"} \
    -o "!{outBam}"
