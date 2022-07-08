#!/bin/sh

TAG="latest"
REPO="nrlabcruk/nrlabtap:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .
#sudo docker push "$REPO"
