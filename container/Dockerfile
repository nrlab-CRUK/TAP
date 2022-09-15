FROM rockylinux:8

RUN dnf install -y dnf-plugins-core epel-release && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y curl gcc git htslib-devel java-17-openjdk java-1.8.0-openjdk procps unzip wget && \
    dnf clean all

# Fastq splitter
# There is a Python one in Anaconda but it won't split by a number of reads.
RUN git clone https://github.com/vasisht/fastq_splitter.git; \
    pushd fastq_splitter; \
    gcc -o /usr/local/bin/splitfastq fastq_splitter.c -lz; \
    popd; \
    rm -rf fastq_splitter

# Groovy 4
# There is no package for Groovy in Anaconda

ARG GROOVY_VERSION=4.0.4

RUN wget -q \
    -O /tmp/groovy-${GROOVY_VERSION}.zip \
    "https://www.apache.org/dyn/closer.lua/groovy/${GROOVY_VERSION}/distribution/apache-groovy-binary-${GROOVY_VERSION}.zip?action=download" && \
    unzip -d /opt /tmp/groovy-${GROOVY_VERSION}.zip && \
    rm -f /tmp/groovy-${GROOVY_VERSION}.zip

# Conda

ARG CONDA_VERSION=py39_4.12.0

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -o miniconda3.sh && \
    mkdir -p /opt && \
    sh miniconda3.sh -b -p /opt/conda && \
    rm miniconda3.sh

COPY AGeNT/* /opt/AGeNT/

COPY nrlab_tap.yml .
RUN /opt/conda/bin/conda env create -f nrlab_tap.yml

RUN /opt/conda/bin/conda clean -a

ENV JAVA_HOME /usr/lib/jvm/jre-17
ENV PATH /opt/groovy-${GROOVY_VERSION}/bin:${JAVA_HOME}/bin:/opt/conda/envs/nrlab_tap/bin:$PATH

RUN Rscript -e "devtools::install_github('hw538/CNAclinic', build_vignettes = FALSE, dependencies = TRUE)"

