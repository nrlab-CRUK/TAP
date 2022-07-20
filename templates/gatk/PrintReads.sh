#!/usr/bin/bash

set -e

# GATK3 requires Java 8. Does not work on Java 11.

!{params.JAVA8} \
    -Xms!{javaMem}m -Xmx!{javaMem}m \
    -jar "!{params.GATK_JAR}" \
    -T PrintReads \
    -R "!{fastaFile}" \
    -I "!{inBam}" \
    -BQSR "!{inTable}" \
    -log .command.log \
    -o "!{outBam}"
