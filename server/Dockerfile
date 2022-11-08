FROM debian:11-slim as slim
RUN apt-get update && apt-get install -y unzip wget git
#
# m2
#
# FROM slim AS m2
# RUN mkdir -p /.m2/repository && \
#   wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip --no-check-certificate && \
#   unzip m2_20220208.zip && \
#   rm m2_20220208.zip
#
# model
#
FROM slim AS model
RUN mkdir demo && \
  cd demo && \
  wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model_step_10000.pt --no-check-certificate
#
# base
#
FROM ubuntu:20.04 AS base
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get update -qq && \
  apt-get install -y -q --no-install-recommends \
	dialog apt-utils \
	build-essential \
	wget \
	unzip \
	maven \
	locales \
  git \
  python3-pip \
	python3-setuptools \
	&& rm -rf /var/lib/apt/lists/*
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

RUN mkdir -p /usr/bin/raki
WORKDIR /usr/bin/raki
ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository -Dmaven.home=/usr/share/maven"
RUN mkdir -p /.m2/repository && \
  wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip --no-check-certificate && \
  unzip m2_20220208.zip && \
  rm m2_20220208.zip
RUN echo \
   "<settings xmlns='http://maven.apache.org/SETTINGS/1.0.0\' \
   xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' \
   xsi:schemaLocation='http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd'> \
       <localRepository>/usr/bin/raki/.m2/repository</localRepository> \
       <interactiveMode>true</interactiveMode> \
       <usePluginRegistry>false</usePluginRegistry> \
       <offline>true</offline> \
   </settings>" \
   > /usr/share/maven/conf/settings.xml;
#
# verbalizer-clone
#
FROM slim AS verbalizer-clone
RUN git clone -b v2 https://github.com/raki-project/raki-verbalizer.git verbalizer
#
# pipeline-clone
#
FROM slim AS pipeline-clone
RUN git clone -b v2.1 https://github.com/raki-project/raki-verbalizer-pipeline.git pipeline
#
# webapp-clone
#
FROM slim AS webapp-clone
RUN git clone -b v2 https://github.com/raki-project/raki-webapp.git webapp
#
# ui-clone
#
FROM slim AS ui-clone
RUN git clone -b main https://github.com/raki-project/raki-ui.git raki-ui
#
# ui
#
FROM node:fermium-slim AS ui
COPY --from=ui-clone raki-ui ./raki-ui
RUN cd raki-ui \
 && npm install \
 && npm run build --prod
#
# app
#
FROM base AS builder
COPY --from=verbalizer-clone verbalizer ./verbalizer
RUN cd verbalizer && \
  mvn -T 1C compile install  -pl owl2nl -am -DskipTests -Dmaven.repo.local=/usr/bin/raki/.m2/repository

COPY --from=pipeline-clone pipeline ./pipeline
RUN cd pipeline && \
  mvn -T 1C install  -am -DskipTests -Dmaven.repo.local=/usr/bin/raki/.m2/repository

COPY --from=webapp-clone webapp ./webapp
COPY ./ontology/* ./webapp/src/main/resources/static/ontology/
COPY --from=ui raki-ui/dist/raki-ui/ ./webapp/src/main/resources/static/
RUN cd webapp && \
  mvn -T 1C compile install -am -DskipTests -Dmaven.repo.local=/usr/bin/raki/.m2/repository
#
# final
#
FROM base AS final
RUN conda create --quiet --yes --name openNMT2 python=3.9 \
  && conda run --name openNMT2 pip install OpenNMT-py==2.3.0

COPY --from=model demo ./demo
COPY --from=builder /usr/bin/raki/.m2 ./.m2
COPY --from=builder /usr/bin/raki/webapp/target ./target
COPY --from=builder /usr/bin/raki/webapp/pom.xml ./

EXPOSE 9081

ENTRYPOINT [ "mvn", "exec:java", "-Dmaven.repo.local=/usr/bin/raki/.m2/repository", "-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
