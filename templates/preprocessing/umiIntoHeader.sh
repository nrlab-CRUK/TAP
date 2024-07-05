#!/bin/bash

python3 "!{projectDir}/python/UMIIntoHeader.py" \
    --read="!{readFastq}" \
    --umi="!{umiFastq}" \
    --out="!{combinedFastq}"
