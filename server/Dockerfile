#
#
#
FROM ubuntu:20.04 AS data

MAINTAINER R. Speck <rene.speck@uni-leipzig.de>
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

RUN mkdir -p /usr/bin/raki
WORKDIR /usr/bin/raki

RUN apt-get update -qq && \
  apt-get install -y -q --no-install-recommends \
	dialog apt-utils \
	python3-pip \
	python3-setuptools \
	build-essential \
	maven \
	wget \
	unzip \
	locales \
  git \
  nodejs npm \
	&& rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN git clone -b v2 https://github.com/raki-project/raki-webapp.git . \
 && git clone -b v2 https://github.com/raki-project/raki-verbalizer.git raki-verbalizer \
 && git clone -b v2.1 https://github.com/raki-project/raki-verbalizer-pipeline.git raki-verbalizer-pipeline \
 && git clone -b main https://github.com/raki-project/raki-ui.git raki-ui \
 && git clone -b master https://github.com/OpenNMT/OpenNMT-py.git OpenNMT

RUN mkdir demo && cd demo && wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model_step_10000.pt

RUN wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip
RUN unzip m2_20220208.zip \
 && echo \
    "<settings xmlns='http://maven.apache.org/SETTINGS/1.0.0\' \
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' \
    xsi:schemaLocation='http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd'> \
        <localRepository>/usr/bin/raki/.m2/repository</localRepository> \
        <interactiveMode>true</interactiveMode> \
        <usePluginRegistry>false</usePluginRegistry> \
        <offline>false</offline> \
    </settings>" \
    > /usr/share/maven/conf/settings.xml;

#
#
#
FROM data AS builder

RUN cd raki-ui \
 && npm install \
 && npm run build --prod \
 && cd .. \
 && cp -r ./raki-ui/dist/raki-ui/* ./src/main/resources/static

ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository -Dmaven.home=/usr/share/maven"

RUN cd raki-verbalizer && ./mavenInstall.sh  \
 && cd raki-verbalizer-pipeline && ./mavenInstall.sh \
 && ./mavenCompile.sh 

#
#
#
FROM builder

RUN rm -r raki-ui \
  && rm -rf raki-verbalizer \
  && rm -rf raki-verbalizer-pipeline \
  && rm m2_20220208.zip

ENV CONDA_DIR /opt/conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh \
  && /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN cd OpenNMT  \
 && conda create --name openNMT2 python=3.9 \
 && conda run --name openNMT2 pip install -e .  \
 && conda run --name openNMT2 python setup.py install

EXPOSE 9081

ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository -Dmaven.home=/usr/share/maven"
ENTRYPOINT ["mvn","exec:java","-Dmaven.repo.local=/usr/bin/raki/.m2/repository","-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
