# multi-stage building:
# First stage just clones the private repo using SSH
#
FROM openjdk:8-jdk

MAINTAINER R. Speck <rene.speck@uni-leipzig.de>

SHELL ["/bin/bash", "-c"]

# install all we need
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  git \
	ssh \
#	maven \
	&& rm -rf /var/lib/apt/lists/*

ARG KEY_VERBALIZER
ARG KEY_PIPELINE
ARG KEY_WEBAPP

RUN mkdir /root/.ssh/

RUN echo "${KEY_VERBALIZER}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN git clone --branch master \
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
