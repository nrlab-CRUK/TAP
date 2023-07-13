#!/bin/bash

set -o
set +e

trimmomatic -Xms!{javaMem}m -Xmx!{javaMem}m PE \
    -threads !{task.cpus} -phred33 \
    "!{read1In}" "!{read2In}" \
    "!{read1Out}" unpaired1.fq.gz \
    "!{read2Out}" unpaired2.fq.gz \
    ILLUMINACLIP:/opt/TruSeq3-PE-2with_rcUMI.fa:1:10:5:9:true MINLEN:20

#if [ $? -eq 0 ]
#then
#    zcat paired1.fq.gz unpaired1.fq.gz | gzip -c -1 > "!{read1Out}" &
#    pid1=$!
#    zcat paired2.fq.gz unpaired2.fq.gz | gzip -c -1 > "!{read2Out}" &
#    pid2=$!
#    wait $pid1 $pid2
#fi

#rm -f paired1.fq.gz unpaired1.fq.gz paired2.fq.gz unpaired2.fq.gz
rm -f unpaired1.fq.gz unpaired2.fq.gz

groovy "!{projectDir}/modules/nextflow-support/removeInput.groovy" !{params.EAGER_CLEANUP} $? \
    !{read1In} \
    !{read2In}
