#!/bin/sh

set -eu

# Builds a Singularity image from the Docker image.
# Use makedocker.sh first.
# See https://stackoverflow.com/a/60316979

TAG="2.0.0"
REPO="nrlabcruk/nrlabtap:$TAG"
IMAGE=nrlabtap-${TAG}.sif

sudo rm -f $IMAGE

sudo singularity build $IMAGE docker-daemon://${REPO}
sudo chown $USER $IMAGE
chmod a-x $IMAGE

