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
	locales \
  git \
	&& rm -rf /var/lib/apt/lists/*
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN mkdir -p /usr/bin/raki
#RUN mkdir -p /usr/bin/raki/.m2/repository
WORKDIR /usr/bin/raki
ENV MAVEN_OPTS "-Xmx8G -Dmaven.repo.local=/usr/bin/raki/.m2/repository -Dmaven.home=/usr/share/maven"
#
# model
#
FROM base AS model
RUN mkdir demo
RUN cd demo && wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/model_step_10000.pt --no-check-certificate
#
# builder-java
#
FROM base AS builder-java
RUN apt-get update -qq && \
  apt-get install -y -q --no-install-recommends \
	maven \
	&& rm -rf /var/lib/apt/lists/*
#
# builder-maven
#
FROM builder-java AS builder-maven
RUN mkdir -p /.m2/repository
RUN wget https://hobbitdata.informatik.uni-leipzig.de/RAKI/VerbalizerModel/m2_20220208.zip --no-check-certificate && \
  unzip m2_20220208.zip && \
  rm m2_20220208.zip

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

#
# builder-python
#
FROM base AS builder-python
RUN apt-get update -qq && \
  apt-get install -y -q --no-install-recommends \
	python3-pip \
	python3-setuptools \
	&& rm -rf /var/lib/apt/lists/*
ENV CONDA_DIR /opt/conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh \
  && /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
#
# builder-nodejs
#
FROM base AS builder-nodejs
RUN apt-get update -qq && \
  apt-get install -y -q --no-install-recommends \
  nodejs npm \
	&& rm -rf /var/lib/apt/lists/*
#
# verbalizer
#
FROM builder-maven AS verbalizer
RUN git clone -b v2 https://github.com/raki-project/raki-verbalizer.git verbalizer
RUN cd verbalizer && \
  mvn -T 1C compile install -pl owl2nl -am -DskipTests \
  -Dmaven.repo.local=/usr/bin/raki/.m2/repository
#
# pipeline
#
FROM verbalizer AS pipeline
RUN git clone -b v2.1 https://github.com/raki-project/raki-verbalizer-pipeline.git pipeline
RUN cd pipeline && \
  mvn -T 1C install -am -DskipTests \
  -Dmaven.repo.local=/usr/bin/raki/.m2/repository
#
# ui
#
FROM builder-nodejs AS ui
RUN git clone -b main https://github.com/raki-project/raki-ui.git raki-ui
RUN cd raki-ui \
 && npm install \
 && npm run build --prod
#
# webapp
#
FROM pipeline AS webapp
RUN  git clone -b v2 https://github.com/raki-project/raki-webapp.git webapp
COPY ./ontology/* ./webapp/src/main/resources/static/ontology/
COPY --from=ui /usr/bin/raki/raki-ui/dist/raki-ui/ ./webapp/src/main/resources/static/
RUN cd webapp && \
  mvn -T 1C compile -am -DskipTests \
  -Dmaven.repo.local=/usr/bin/raki/.m2/repository
#
# nmt
#
FROM builder-python AS nmt
RUN git clone -b master https://github.com/OpenNMT/OpenNMT-py.git OpenNMT
RUN cd OpenNMT  \
 && conda create --quiet --yes --name openNMT2 python=3.9 \
 && conda run --name openNMT2 pip install -e .  \
 && conda run --name openNMT2 python setup.py install
#
# final
#
FROM webapp AS final
COPY --from=model /usr/bin/raki/demo ./demo
COPY --from=nmt /usr/bin/raki/OpenNMT ./OpenNMT
COPY --from=webapp /usr/bin/raki/webapp/target ./target
COPY --from=webapp /usr/bin/raki/webapp/pom.xml ./

EXPOSE 9081
#
ENTRYPOINT [ "mvn", "exec:java", "-Dmaven.repo.local=/usr/bin/raki/.m2/repository", "-Dexec.mainClass=org.dice_research.raki.verbalizer.webapp.ServiceApp"]
#
