#!/bin/bash

python3 "!{projectDir}/python/FastqSplit.py" \
    --source="!{fastqFile}" \
    --prefix="!{nameBase}" \
    --reads=!{params.CHUNK_SIZE}
