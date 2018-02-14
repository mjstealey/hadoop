FROM krallin/centos-tini:centos7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

ARG HADOOP_VERSION=2.9.0

# Set correct environment variables.
ENV	HOME=/root \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# java 8: https://github.com/binarybabel/docker-jdk/blob/master/src/centos.Dockerfile
ENV JAVA_DOWNLOAD=http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.rpm
RUN cd /tmp \
    && curl -o jdk.rpm -jfksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
       "${JAVA_DOWNLOAD:-$(curl -s https://lv.binarybabel.org/catalog-api/java/jdk8.txt?p=downloads.rpm)}" \
    && rpm -Uvh jdk.rpm && rm jdk.rpm \
    && echo "export JAVA_HOME=/usr/java/default/" > /etc/profile.d/java_home.sh

# apache hadoop
ARG HADOOP_INSTALL_DIR=/home/hadoop
RUN yum install -y \
    openssh-server \
    openssh-clients \
    which
RUN adduser -m -d $HADOOP_INSTALL_DIR hadoop
WORKDIR $HADOOP_INSTALL_DIR
USER hadoop
RUN curl -o hadoop-$HADOOP_VERSION.tar.gz "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    && tar xzf hadoop-$HADOOP_VERSION.tar.gz \
    && mv hadoop-$HADOOP_VERSION hadoop \
    && rm -f hadoop-HADOOP_VERSION.tar.gz \
    && yum clean all

RUN mkdir -p /home/hadoop/hdfs/namenode \
    && mkdir -p /home/hadoop/hdfs/datanode \
    && mkdir -p /home/hadoop/public

WORKDIR /root/
USER root
RUN ssh-keygen -q -N '' -t rsa -f /root/.ssh/id_rsa \
    && ssh-keygen -q -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key \
    && ssh-keygen -q -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N '' -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -q -N '' -t ed25519 -f /etc/ssh/ssh_host_ed25519_key \
    && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys \
    && chmod 0600 /root/.ssh/authorized_keys

ENV HADOOP_USER_HOME=${HADOOP_INSTALL_DIR} \
    HADOOP_PREFIX=${HADOOP_INSTALL_DIR}/hadoop \
    HADOOP_INSTALL=${HADOOP_PREFIX} \
    HADOOP_MAPRED_HOME=${HADOOP_PREFIX} \
    HADOOP_COMMON_HOME=${HADOOP_PREFIX} \
    HADOOP_HDFS_HOME=${HADOOP_PREFIX} \
    YARN_HOME=${HADOOP_PREFIX} \
    HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_PREFIX}/lib/native \
    HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop \ PATH=$PATH:${HADOOP_PREFIX}/sbin:${HADOOP_PREFIX}/bin

ENV IS_NODE_MANAGER=true \
    IS_NAME_NODE=true \
    IS_SECONDARY_NAME_NODE=true \
    IS_DATA_NODE=true \
    IS_RESOURCE_MANAGER=true \
    CLUSTER_NODES=localhost

VOLUME ["/site-files"]

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
