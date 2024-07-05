#!/bin/bash

set -u
set +e

java !{javaMem} \
    -jar /opt/AGeNT/trimmer.jar \
     -fq1 "!{read1In}" \
     -fq2 "!{read2In}" \
     -out "./!{outFilePrefix}" \
     -v2 \
     -minFractionRead !{params.TRIM_MINIMUM_FRACTION_READ} \
     -qualityTrimming !{params.TRIM_QUALITY_THRESHOLD}

groovy "!{projectDir}/modules/nextflow-support/outOfMemoryCheck.groovy" $?

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    !{read1In} \
    !{read2In}
