FROM centos:7

MAINTAINER Aleksey Lebedev FOPS-10

RUN groupadd -g 1000 elasticsearch && useradd elasticsearch -u 1000 -g 1000

RUN yum install -y java-1.8.0-openjdk

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
RUN echo -e "[elasticsearch-7.x]\nname=Elasticsearch repository for 7.x packages\nbaseurl=https://artifacts.elastic.co/packages/7.x/yum\ngpgcheck=1\ngpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\nenabled=1\nautorefresh=1\nty$
RUN yum install -y elasticsearch
RUN mkdir /etc/elasticsearch/snapshots

COPY elasticsearch.yml /etc/elasticsearch/

USER elasticsearch

EXPOSE 9200


CMD ["/usr/share/elasticsearch/bin/elasticsearch"]
