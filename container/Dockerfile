FROM rockylinux:latest

RUN dnf update -y && \
    dnf install -y git curl procps && \
    dnf clean all

ARG CONDA_VERSION=py39_4.10.3

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm miniconda3.sh

COPY AGeNT/* /opt/AGeNT/

COPY nrlab_tap.yml .
RUN /opt/conda/bin/conda env create -f nrlab_tap.yml

RUN /opt/conda/bin/conda clean -a

ENV PATH /opt/conda/envs/nrlab_tap/bin:$PATH
