#!/bin/sh

set -eu

# Builds a Singularity image from the Docker image.
# Use makedocker.sh first.
# See https://stackoverflow.com/a/60316979

TAG="latest"
REPO="nrlabcruk/nrlabtap:$TAG"
IMAGE=nrlabtap.sif

sudo rm -f $IMAGE

sudo singularity build $IMAGE docker-daemon://${REPO}
sudo chown $USER $IMAGE
chmod a-x $IMAGE

