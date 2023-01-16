#!/bin/bash

set -eu

java -Xms!{javaMem}m -Xmx!{javaMem}m \
    -jar /opt/AGeNT/trimmer.jar \
     -fq1 "!{read1In}" \
     -fq2 "!{read2In}" \
     -out "./!{outFilePrefix}" \
     -v2 \
     -minFractionRead !{params.TRIM_MINIMUM_FRACTION_READ} \
     -qualityTrimming !{params.TRIM_QUALITY_THRESHOLD}

groovy "!{projectDir}/groovy/outOfMemoryCheck.groovy" $?

groovy "!{projectDir}/groovy/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    !{read1In} \
    !{read2In}
