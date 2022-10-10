set -eou pipefail

# TODO upgrade to latest version of AGeNT and use -v2 option for SureSelect XT HS2 libraries

java -Xms!{javaMem}m -Xmx!{javaMem}m \
    -jar /opt/AGeNT/SurecallTrimmer_v4.0.1.jar \
     -fq1 "!{read1In}" \
     -fq2 "!{read2In}" \
     -xt \
     -minFractionRead !{params.TRIM_MINIMUM_FRACTION_READ} \
     -qualityTrimming !{params.TRIM_QUALITY_THRESHOLD}
