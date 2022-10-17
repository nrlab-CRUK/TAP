#!/bin/bash

set -eu

runIchorCNA.R \
    --id "!{sampleId}" \
    --WIG "!{wiggleFile}" \
    --ploidy "!{params.ICHORCNA_PLOIDY}" \
    --normal "!{params.ICHORCNA_NORMAL}" \
    --maxCN !{params.ICHORCNA_MAXIMUM_COPYNUMBER} \
    --gcWig "!{params.ICHORCNA_PACKAGE_DATA_DIR}/!{ichorParams.ICHORCNA_GC_WIGGLE}" \
    --mapWig "!{params.ICHORCNA_PACKAGE_DATA_DIR}/!{ichorParams.ICHORCNA_MAP_WIGGLE}" \
    --centromere "!{params.ICHORCNA_PACKAGE_DATA_DIR}/!{ichorParams.ICHORCNA_CENTROMERE}" \
    --normalPanel "!{params.ICHORCNA_PACKAGE_DATA_DIR}/!{ichorParams.ICHORCNA_NORMAL_PANEL}" \
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

head -2 "!{sampleId}.params.txt" > ichorCNA.tumour_fraction_and_ploidy.txt

Rscript --vanilla "!{projectDir}/R/tMAD.R" \
    --input "!{sampleId}.seg" \
    --output "ichorCNA.tMAD.txt" \
    --sample_column "sample" \
    --segmented_column "median" \
    --bin_count_column "bins" \
    --max_log_ratio 5.0
