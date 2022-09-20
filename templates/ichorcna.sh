#!/bin/bash

set -eu

Rscript --vanilla /opt/conda/envs/nrlab_tap/share/r-ichorcna*/scripts/runIchorCNA.R \
    --id "!{sampleId}_plots" \
    --WIG "!{wiggleFile}" \
    --ploidy "!{params.ICHORCNA_PLOIDY}" \
    --normal "!{params.ICHORCNA_NORMAL}" \
    --maxCN !{params.ICHORCNA_MAXIMUM_COPYNUMBER} \
    --gcWig "!{gcWiggle}" \
    --mapWig "!{mapWiggle}" \
    --centromere "!{centromere}" \
    --normalPanel "!{normalPanel}" \
    --includeHOMD !{params.ICHORCNA_INCLUDE_HOMD} \
    --chrs "!{params.ICHORCNA_CHROMOSOMES}" \
    --chrTrain "!{params.ICHORCNA_TRAINING_CHROMOSOMES}" \
    --estimateNormal !{params.ICHORCNA_ESTIMATE_NORMAL} \
    --estimatePloidy !{params.ICHORCNA_ESTIMATE_PLOIDY} \
    --estimateScPrevalence true \
    --scStates "!{params.ICHORCNA_SUBCLONAL_STATES}" \
    --txnE !{params.ICHORCNA_TXN_E} \
    --txnStrength !{params.ICHORCNA_TXN_STRENGTH} \
    --outDir "./" \
    --plotYLim "!{params.ICHORCNA_PLOT_Y_LIMITS}" \
    --plotFileType "!{params.ICHORCNA_PLOT_FILE_TYPE}" \
    --exons "!{params.ICHORCNA_EXONS}" \
    --minMapScore !{params.ICHORCNA_MINIMUM_MAP_SCORE}
