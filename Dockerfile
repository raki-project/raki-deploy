# multi-stage building:
# First stage just clones the private repo using SSH
#
FROM openjdk:8-jdk as cloner

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

FROM openjdk:8-jdk

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
	maven \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=cloner /raki-verbalizer /src/raki-verbalizer
COPY --from=cloner /raki-verbalizer-pipeline /src/raki-verbalizer-pipeline
COPY --from=cloner /raki-verbalizer-webapp /src/raki-verbalizer-webapp

EXPOSE 4443

RUN cd /src/raki-verbalizer && ./mavenCompile.sh && ./mavenInstall.sh 
RUN cd /src/raki-verbalizer-pipeline && ./mavenCompile.sh && ./mavenInstall.sh 
RUN cd /src/raki-verbalizer-webapp && ./mavenCompile.sh

CMD ["cd /src/raki-verbalizer-webapp && ./mavenExecute.sh"] 