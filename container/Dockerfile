FROM rockylinux:8

RUN dnf install -y dnf-plugins-core epel-release && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y curl gcc git htslib-devel java-17-openjdk java-1.8.0-openjdk procps unzip wget && \
    dnf clean all

# Conda

ARG CONDA_VERSION=py39_4.12.0

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm miniconda3.sh

COPY nrlab_tap.yml connor.yml ./
RUN /opt/conda/bin/conda env create -f nrlab_tap.yml
RUN /opt/conda/bin/conda env create -f connor.yml

RUN /opt/conda/bin/conda clean -a

# create symbolic link to the directory containing the ichorCNA reference data
# files which contains a version number
RUN ln -s /opt/conda/envs/nrlab_tap/share/r-ichorcna-* /opt/conda/envs/nrlab_tap/share/r-ichorcna

ARG AGENT_VERSION=3.0.5
COPY AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/
RUN ln -s /opt/AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/trimmer.jar

ENV JAVA_HOME /usr/lib/jvm/jre-17
ENV PATH ${JAVA_HOME}/bin:/opt/conda/envs/nrlab_tap/bin:/opt/conda/envs/connor/bin:$PATH
