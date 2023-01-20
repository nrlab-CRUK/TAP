#!/bin/bash

set -o
set +e

# See the help for trim_galore for --cores and why it's divided by four.
# It is recommended to give the task 16 cores as a sweet spot.

trim_galore \
    --paired --illumina --gzip --length=0 \
    --basename="!{outFilePrefix}" \
    --cores=!{Math.max(1, (int)Math.ceil(task.cpus / 4.0))} \
    !{read1In} !{read2In}

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    !{read1In} \
    !{read2In}
