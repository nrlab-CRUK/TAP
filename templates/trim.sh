set -eou pipefail

java -jar /opt/AGeNT/SurecallTrimmer_v4.0.1.jar \
     -fq1 "!{read1}" \
     -fq2 "!{read2}" \
     -xt -minFractionRead !{params.TRIM_MINIMUM_FRACTION_READ} -qualityTrimming !{params.TRIM_QUALITY_THRESHOLD}
