#!/bin/sh

set -eu

TAG="latest"
REPO="nrlabcruk/nrlabtap:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .
