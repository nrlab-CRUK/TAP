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

COPY tap.yml connor.yml ./
RUN /opt/conda/bin/conda env create -f tap.yml
RUN /opt/conda/bin/conda env create -f connor.yml

RUN /opt/conda/bin/conda clean -a

# create symbolic link to the directory containing the ichorCNA reference data
# files which contains a version number
RUN ln -s /opt/conda/envs/tap/share/r-ichorcna-* /opt/conda/envs/tap/share/r-ichorcna

# There is no groovy in conda

ARG GROOVY_VERSION=4.0.12
RUN wget -O /tmp/groovy.zip https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-${GROOVY_VERSION}.zip && \
    unzip -d /opt /tmp/groovy.zip && \
    rm -f /tmp/groovy.zip

ARG AGENT_VERSION=3.0.5
COPY AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/
RUN ln -s /opt/AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/trimmer.jar

RUN wget -O /opt/TruSeq3-PE-2with_rcUMI.fa https://takarabio.com/resourcedocument/x108592

ENV JAVA_HOME /usr/lib/jvm/jre-17
ENV GROOVY_HOME /opt/groovy-${GROOVY_VERSION}
ENV PATH ${JAVA_HOME}/bin:${GROOVY_HOME}/bin:/opt/conda/envs/tap/bin:/opt/conda/envs/connor/bin:$PATH
