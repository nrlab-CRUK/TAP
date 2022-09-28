set -eou pipefail

python3 "!{projectDir}/python/TagTrim2.py" \
--read1="!{read1In}" --read2="!{read2In}" \
--out1="!{read1Out}" --out2="!{read2Out}" \
--umi1="!{umi1Out}" --umi2="!{umi2Out}"
