#!/bin/bash

python3 "!{projectDir}/python/FastqSplit.py" \
    --source="!{sourceFile}" \
    !{umiArg} \
    --prefix="!{nameBase}" \
    --reads=!{params.CHUNK_SIZE}
