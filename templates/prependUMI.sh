set -eou pipefail

seqkit concat -w 0 "!{umiread}" "!{read1}" -o "!{read1out}"
seqkit concat -w 0 "!{umiread}" "!{read2}" -o "!{read2out}"
