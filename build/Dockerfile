# multi-stage building:
# First stage just clones the private repo using SSH
#
FROM openjdk:8-jdk AS cloner

MAINTAINER R. Speck <rene.speck@uni-leipzig.de>

SHELL ["/bin/bash", "-c"]

# install all we need
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  git \
	ssh \
	&& rm -rf /var/lib/apt/lists/*

ARG KEY_VERBALIZER
ARG KEY_PIPELINE
ARG KEY_WEBAPP

RUN mkdir /root/.ssh/

RUN echo "${KEY_VERBALIZER}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN git clone --branch dev_owl2nl \
  ssh://git@github.com/raki-project/raki-verbalizer.git  \
  raki-verbalizer

RUN echo "${KEY_PIPELINE}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN git clone --branch main \
  ssh://git@github.com/raki-project/raki-verbalizer-pipeline.git \
  raki-verbalizer-pipeline

RUN echo "${KEY_WEBAPP}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN git clone --branch master \
  ssh://git@github.com/raki-project/raki-verbalizer-webapp.git \
  raki-verbalizer-webapp

RUN git clone --branch master \
  https://github.com/OpenNMT/OpenNMT-py.git \
  OpenNMT
RUN cd OpenNMT && git checkout 585499a4
#
#
FROM ubuntu:latest AS builder
RUN mkdir -p /usr/bin/raki-verbalizer-webapp
WORKDIR /usr/bin/raki-verbalizer-webapp

ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki-verbalizer-webapp/m2repository"

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
	python3-pip \
	python3-setuptools \
	build-essential \
	apt-utils \
	maven \
	&& rm -rf /var/lib/apt/lists/*

COPY m2repository m2repository
COPY --from=cloner /raki-verbalizer raki-verbalizer
COPY --from=cloner /raki-verbalizer-pipeline raki-verbalizer-pipeline
COPY --from=cloner /raki-verbalizer-webapp ./
COPY demo demo
# COPY requirements.txt requirements.txt

EXPOSE 4443

RUN cd raki-verbalizer && ./mavenCompile.sh && ./mavenInstall.sh 
RUN cd raki-verbalizer-pipeline && ./mavenCompile.sh && ./mavenInstall.sh 
RUN ./mavenCompile.sh

RUN rm -rf raki-verbalizer 
RUN rm -rf raki-verbalizer-pipeline 

#RUN pip3 install -r requirements.txt
RUN pip3 install wheel
RUN pip3 install future==0.18.2 numpy==1.20.2 torch==1.6.0 sentencepiece==0.1.95 torchtext==0.5.0
COPY --from=cloner OpenNMT OpenNMT
RUN cd OpenNMT && pip3 install -e .

#
# Test
#
# RUN cd OpenNMT && python3 translate.py \
#		-model /usr/bin/raki-verbalizer-webapp/demo/model_step_1000.pt \
#		-src /usr/bin/raki-verbalizer-webapp/demo/suramin_5k.owl.json.src.test.txt  \
#		-output /usr/bin/raki-verbalizer-webapp/demo/pred.txt \
#		-replace_unk \
#		-verbose \
#		-beam_size 5

ENTRYPOINT ["mvn","exec:java","-Dmaven.repo.local=/usr/bin/raki-verbalizer-webapp/m2repository","-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
