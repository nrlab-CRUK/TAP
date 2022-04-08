FROM rockylinux:latest

RUN dnf install -y dnf-plugins-core epel-release && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y gcc git curl procps htslib-devel && \
    dnf clean all

# Fastq splitter
# There is a Python one in Anaconda but it won't split by a number of reads.
RUN git clone https://github.com/vasisht/fastq_splitter.git; \
    pushd fastq_splitter; \
    gcc -o /usr/local/bin/splitfastq fastq_splitter.c -lz; \
    popd; \
    rm -rf fastq_splitter

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
