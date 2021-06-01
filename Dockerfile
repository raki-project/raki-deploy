# multi-stage building:
# First stage just clones
#
FROM openjdk:8-jdk AS cloner

MAINTAINER R. Speck <rene.speck@uni-leipzig.de>

SHELL ["/bin/bash", "-c"]

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  git \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone --branch v1 \
  https://github.com/raki-project/raki-verbalizer.git  \
  raki-verbalizer

RUN git clone --branch main \
  https://github.com/raki-project/raki-verbalizer-pipeline.git \
  raki-verbalizer-pipeline 

RUN git clone --branch master \
  https://github.com/OpenNMT/OpenNMT-py.git \
  OpenNMT && \
	cd OpenNMT && \
	git checkout 585499a4

RUN git clone --branch master \
 https://github.com/raki-project/raki-verbalizer-webapp.git \
  raki-verbalizer-webapp	&& cd  raki-verbalizer-webapp 

# Second stage to build
#
FROM ubuntu:latest AS builder

RUN mkdir -p /usr/bin/raki-verbalizer-webapp
WORKDIR /usr/bin/raki-verbalizer-webapp

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
	python3-pip \
	python3-setuptools \
	build-essential \
	apt-utils \
	maven \
	wget \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki-verbalizer-webapp/m2repository"
RUN mkdir demo && cd demo && wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model_step_1000.pt
RUN wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2repository.zip
RUN unzip m2repository.zip

COPY --from=cloner /raki-verbalizer raki-verbalizer
COPY --from=cloner /raki-verbalizer-pipeline raki-verbalizer-pipeline
COPY --from=cloner /raki-verbalizer-webapp ./
#COPY --from=cloner /OntoPy OntoPy

EXPOSE 9081

RUN cd raki-verbalizer && ./mavenCompile.sh && ./mavenInstall.sh 
RUN cd raki-verbalizer-pipeline && ./mavenCompile.sh && ./mavenInstall.sh 
RUN ./mavenCompile.sh

RUN rm -rf raki-verbalizer 
RUN rm -rf raki-verbalizer-pipeline 
RUN rm -rf m2repository.zip

RUN pip3 install wheel future==0.18.2 numpy==1.20.2 torch==1.6.0 sentencepiece==0.1.95 torchtext==0.5.0
COPY --from=cloner OpenNMT OpenNMT
RUN cd OpenNMT && pip3 install -e .

ENTRYPOINT ["mvn","exec:java","-Dmaven.repo.local=/usr/bin/raki-verbalizer-webapp/m2repository","-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
