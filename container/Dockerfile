FROM rockylinux:8

RUN dnf install -y dnf-plugins-core epel-release && \
    dnf makecache && \
    dnf update -y && \
    dnf install -y curl gcc git htslib-devel java-21-openjdk procps unzip wget && \
    dnf clean all

# Conda

ARG MINIFORGE_VERSION=24.3.0-0

RUN curl -L -O https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/miniforge3-linux-x86_64.sh && \
    mkdir -p /opt && \
    sh miniforge3-linux-x86_64.sh -b -p /opt/miniforge3 && \
    rm miniforge3-linux-x86_64.sh

COPY tap.yml requirements.txt ./
RUN /opt/miniforge3/bin/mamba env create -f tap.yml && /opt/miniforge3/bin/mamba clean -a

# There is no groovy in conda

ARG GROOVY_VERSION=4.0.24
RUN wget -O /tmp/groovy.zip https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-${GROOVY_VERSION}.zip && \
    unzip -d /opt /tmp/groovy.zip && \
    rm -f /tmp/groovy.zip

ARG AGENT_VERSION=3.0.5
COPY AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/
RUN ln -s /opt/AGeNT/trimmer-${AGENT_VERSION}.jar /opt/AGeNT/trimmer.jar

RUN wget -O /opt/TruSeq3-PE-2with_rcUMI.fa https://takarabio.com/resourcedocument/x108592

ENV JAVA_HOME /usr/lib/jvm/jre-21
ENV GROOVY_HOME /opt/groovy-${GROOVY_VERSION}
ENV PATH ${JAVA_HOME}/bin:${GROOVY_HOME}/bin:/opt/miniforge3/envs/tap/bin:$PATH

# Install Python add-ons using pip

RUN pip install --upgrade -r requirements.txt
