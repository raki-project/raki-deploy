FROM ubuntu

MAINTAINER R. Speck <rene.speck@uni-leipzig.de>

SHELL ["/bin/bash", "-c"]

RUN mkdir -p /usr/bin/raki
WORKDIR /usr/bin/raki

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
	python3-pip \
	python3-setuptools \
	build-essential \
	apt-utils \
	maven \
	wget \
	unzip \
	locales \
	git \
	&& rm -rf /var/lib/apt/lists/*

RUN pip3 install wheel future==0.18.2 numpy==1.20.2 torch==1.6.0 sentencepiece==0.1.95 torchtext==0.5.0

RUN locale-gen en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN git clone --branch v1 \
 https://github.com/raki-project/raki-webapp.git \
  .

RUN git clone --branch master \
  https://github.com/OpenNMT/OpenNMT-py.git \
  OpenNMT && \
	cd OpenNMT && \
	git checkout 585499a4
RUN cd OpenNMT && pip3 install -e .
#
RUN wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip
RUN unzip m2_20220208.zip && rm m2_20220208.zip

RUN echo \
    "<settings xmlns='http://maven.apache.org/SETTINGS/1.0.0\' \
    xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' \
    xsi:schemaLocation='http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd'> \
        <localRepository>/usr/bin/raki/.m2/repository</localRepository> \
        <interactiveMode>true</interactiveMode> \
        <usePluginRegistry>false</usePluginRegistry> \
        <offline>false</offline> \
    </settings>" \
    > /usr/share/maven/conf/settings.xml;

RUN mkdir demo && cd demo && wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model_step_1000.pt

RUN git clone --branch v1 \
  https://github.com/raki-project/raki-verbalizer.git  \
  raki-verbalizer

RUN git clone --branch v1 \
  https://github.com/raki-project/raki-verbalizer-pipeline.git \
  raki-verbalizer-pipeline

RUN cd raki-verbalizer && ./mavenInstall.sh && cd .. && rm -rf raki-verbalizer \
 && cd raki-verbalizer-pipeline && ./mavenInstall.sh  && cd .. && rm -rf raki-verbalizer-pipeline \
 && ./mavenCompile.sh

# RUN echo "$(ls -sha)"

EXPOSE 9081

ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository"

ENTRYPOINT ["mvn","exec:java","-Dmaven.repo.local=/usr/bin/raki/.m2/repository","-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
