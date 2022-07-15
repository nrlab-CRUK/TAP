set -eou pipefail

groovy \
-Dlog4j.configurationFile="!{projectDir}/groovy/tagtrim/log4j2.xml" \
--classpath="!{projectDir}/groovy/tagtrim" \
"!{projectDir}/groovy/tagtrim/tagtrim.groovy" \
--read1="!{read1In}" --read2="!{read2In}" \
--out1="!{read1Out}" --out2="!{read2Out}" \
--umi1="!{umi1Out}" --umi2="!{umi2Out}"
