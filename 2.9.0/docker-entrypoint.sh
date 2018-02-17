#!/usr/bin/env bash
set -e

HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
CORE_SITE_FILE=${HADOOP_CONF_DIR}/core-site.xml
HDFS_SITE_FILE=${HADOOP_CONF_DIR}/hdfs-site.xml
MAPRED_SITE_FILE=${HADOOP_CONF_DIR}/mapred-site.xml
YARN_SITE_FILE=${HADOOP_CONF_DIR}/yarn-site.xml
WORKERS_FILE=${HADOOP_CONF_DIR}/slaves

_core_site_xml () {
  if [ -f /site-files/core-site.xml ]; then
    echo "USE: /site-files/core-site.xml"
    cat /site-files/core-site.xml > $CORE_SITE_FILE
  else
    cat > $CORE_SITE_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $CORE_SITE_FILE
}

_hdfs_site_xml () {
  if [ -f /site-files/hdfs-site.xml ]; then
    cat /site-files/hdfs-site.xml > $HDFS_SITE_FILE
  else
    cat > $HDFS_SITE_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.name.dir</name>
    <value>file:///home/hadoop/hadoopdata/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>file:///home/hadoop/hadoopdata/hdfs/datanode</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $HDFS_SITE_FILE
}

_mapred_site_xml() {
  if [ -f /site-files/mapred-site.xml ]; then
    cat /site-files/mapred-site.xml > $MAPRED_SITE_FILE
  else
    cat > $MAPRED_SITE_FILE << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $MAPRED_SITE_FILE
}

_yarn_site_xml() {
  if [ -f /site-files/yarn-site.xml ]; then
    cat /site-files/yarn-site.xml > $YARN_SITE_FILE
  else
    cat > $YARN_SITE_FILE << EOF
<?xml version="1.0"?>
<!-- Site specific YARN configuration properties -->
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $YARN_SITE_FILE
}

_workers() {
  if [ -f /site-files/workers ]; then
    cat /site-files/workers > $WORKERS_FILE
  else
    cat > $WORKERS_FILE << EOF
localhost
EOF
  fi
  chown hadoop:hadoop $WORKERS_FILE
}

_hadoop_profile() {
  cat > /etc/profile.d/hadoop.sh << EOF
export HADOOP_USER_HOME=${HADOOP_USER_HOME}
export HADOOP_HOME=${HADOOP_USER_HOME}/hadoop
export HADOOP_PREFIX=${HADOOP_USER_HOME}/hadoop
export HADOOP_INSTALL=${HADOOP_PREFIX}
export HADOOP_MAPRED_HOME=${HADOOP_PREFIX}
export HADOOP_COMMON_HOME=${HADOOP_PREFIX}
export HADOOP_HDFS_HOME=${HADOOP_PREFIX}
export JAVA_LIBRARY_PATH=${JAVA_LIBRARY_PATH}:${HADOOP_PREFIX}/lib/native
export YARN_HOME=${HADOOP_PREFIX}
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_PREFIX}/lib/native
export HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
export CORE_SITE_FILE=${HADOOP_CONF_DIR}/core-site.xml
export HDFS_SITE_FILE=${HADOOP_CONF_DIR}/hdfs-site.xml
export MAPRED_SITE_FILE=${HADOOP_CONF_DIR}/mapred-site.xml
export YARN_SITE_FILE=${HADOOP_CONF_DIR}/yarn-site.xml
export WORKERS_FILE=${HADOOP_CONF_DIR}/slaves
export PATH=$PATH:${HADOOP_PREFIX}/sbin:${HADOOP_PREFIX}/bin
EOF
}

_generate_ssh_keys() {
  mkdir -p $HADOOP_USER_HOME/.ssh
  ssh-keygen -t rsa -N '' -f $HADOOP_USER_HOME/.ssh/id_rsa
  cat $HADOOP_USER_HOME/.ssh/id_rsa.pub >> $HADOOP_USER_HOME/.ssh/authorized_keys
  chmod 0600 $HADOOP_USER_HOME/.ssh/authorized_keys
  chown -R hadoop:hadoop $HADOOP_USER_HOME/.ssh
}

_hadoop_profile
# runuser -l hadoop -c $'env' # debug hadoop env

if $IS_NAME_NODE; then
  mkdir -p /hdfsdata/namenode
  chown -R hadoop:hadoop /hdfsdata/namenode
fi
if $IS_DATA_NODE; then
  mkdir -p /hdfsdata/datanode
  chown -R hadoop:hadoop /hdfsdata/datanode
fi

chown -R hadoop:hadoop /home/hadoop/public

/usr/sbin/sshd -D &

runuser -l hadoop -c $'sed -i \'s:export JAVA_HOME=.*:export JAVA_HOME=/usr/java/jdk1.8.0_161/jre:\' /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh'

_core_site_xml
_hdfs_site_xml
_mapred_site_xml
_yarn_site_xml
_workers

IS_FIRST_RUN=$(if [ ! -f "/home/hadoop/.ssh/id_rsa.pub" ]; then echo 'true'; else echo 'false'; fi)

if $IS_NAME_NODE; then
  if $IS_FIRST_RUN; then
  echo "NameNode copy ssh"
    _generate_ssh_keys
    cp -r /home/hadoop/.ssh /home/hadoop/public/
  fi
else
  while [ ! -d /home/hadoop/public/.ssh ]; do
    echo "waiting for /home/hadoop/public/.ssh"
    sleep 2
  done
  if $IS_FIRST_RUN; then
    echo "COPY: .ssh from namenode to $(hostname)"
    cp -rf /home/hadoop/public/.ssh /home/hadoop/
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
    chown -R hadoop:hadoop /home/hadoop/.ssh
  fi
fi

if $IS_FIRST_RUN; then
  while read node; do
    echo "node = $node"
    until runuser -l hadoop -c $'ssh-keyscan $node >> /home/hadoop/.ssh/known_hosts'; do sleep 2; done
  done < <($CLUSTER_NODES)
fi

if $IS_NAME_NODE; then
    echo "Staring NameNode"
    if $IS_FIRST_RUN; then
      runuser -l hadoop -c $'$HADOOP_PREFIX/bin/hdfs namenode -format'
    fi
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode'
fi

if $IS_SECONDARY_NAME_NODE; then
    echo "Staring SecondaryNameNode"
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start secondarynamenode'
fi

if $IS_DATA_NODE; then
    echo "Staring DataNode"
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode'
fi

if $IS_RESOURCE_MANAGER; then
    echo "Staring ResourceManager"
    runuser -l hadoop -c $'$YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager'
fi

if $IS_NODE_MANAGER; then
    echo "Staring NodeManager"
    runuser -l hadoop -c $'$YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start nodemanager'
fi

tail -f /dev/null

exec "$@"
