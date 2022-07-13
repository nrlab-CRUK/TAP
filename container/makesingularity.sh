#!/bin/sh

sudo rm -rf nrlabtap_sandbox nrlabtap.sif

# See https://stackoverflow.com/a/60316979
#sudo singularity build --sandbox nrlabtap_sandbox docker-daemon://nrlabcruk/nrlabtap:latest
sudo singularity build nrlabtap.sif docker-daemon://nrlabcruk/nrlabtap:latest
