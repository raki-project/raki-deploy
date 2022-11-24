FROM debian:11-slim as slim
RUN apt-get update && apt-get install -y unzip wget git
#
# model
#
FROM slim AS model
RUN mkdir model && \
  cd model && \
  wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model.zip --no-check-certificate  && \
    unzip model.zip && \
    rm model.zip
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
ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository"
RUN mkdir -p /.m2/repository && \
  wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip --no-check-certificate && \
  unzip m2_20220208.zip && \
  rm m2_20220208.zip
#
# verbalizer-clone
#
FROM slim AS verbalizer-clone
RUN git clone https://github.com/raki-project/raki-verbalizer.git verbalizer
#
# pipeline-clone
#
FROM slim AS pipeline-clone
RUN git clone https://github.com/raki-project/raki-verbalizer-pipeline.git pipeline && cd pipeline && git checkout v2.2
#
# webapp-clone
#
FROM slim AS webapp-clone
RUN git clone https://github.com/raki-project/raki-webapp.git webapp
#
# ui-clone
#
FROM slim AS ui-clone
RUN git clone https://github.com/raki-project/raki-ui.git raki-ui
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
  mvn -T 1C install -pl owl2nl -o -am -B -Dmaven.repo.local=/usr/bin/raki/.m2/repository

COPY --from=pipeline-clone pipeline ./pipeline
RUN cd pipeline && \
  mvn -T 1C install -am -B -Dmaven.repo.local=/usr/bin/raki/.m2/repository

COPY --from=webapp-clone webapp ./webapp
COPY ./ontology/* ./webapp/src/main/resources/static/ontology/
COPY --from=ui raki-ui/dist/raki-ui/ ./webapp/src/main/resources/static/
RUN cd webapp && \
  mvn -T 1C compile -am -B -Dmaven.repo.local=/usr/bin/raki/.m2/repository
#
# final
#
FROM base AS final

RUN conda create --quiet --yes --name rakiEnv python=3.9
RUN conda run --name rakiEnv pip install sentencepiece==0.1.96 subword-nmt==0.3.7 OpenNMT-py==2.3.0
SHELL ["conda", "run", "-n", "rakiEnv", "/bin/bash", "-c"]
RUN conda run --name rakiEnv conda install  sentencepiece

COPY --from=model model ./model
COPY --from=builder /usr/bin/raki/.m2 ./.m2
COPY --from=builder /usr/bin/raki/webapp/target ./target
COPY --from=builder /usr/bin/raki/webapp/pom.xml ./
COPY --from=builder /usr/bin/raki/pipeline/config.properties ./

EXPOSE 9081
ENTRYPOINT ["conda", "run", "-n", "rakiEnv", "mvn", "exec:java", "-Dmaven.repo.local=/usr/bin/raki/.m2/repository", "-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
