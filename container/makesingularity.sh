#!/bin/sh

# Builds a Singularity image from the Docker image.
# Use makedocker.sh first.
# See https://stackoverflow.com/a/60316979

TAG="latest"
REPO="nrlabcruk/nrlabtap:$TAG"

sudo rm -rf nrlabtap_sandbox nrlabtap.sif

#sudo singularity build --sandbox nrlabtap_sandbox docker-daemon://${REPO}
sudo singularity build nrlabtap.sif docker-daemon://${REPO}
