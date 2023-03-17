#!/bin/sh

set -eu

TAG="2.0.0"
REPO="nrlabcruk/nrlabtap:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .

