# Apache Hadoop in Docker

This work has been inspired by:

- techadmin.net: [Setup Hadoop cluster on CentOS](https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/)
- Oracle Java 8: [binarybabel/docker-jdk](https://github.com/binarybabel/docker-jdk/blob/master/src/centos.Dockerfile)
- CentOS 7 base image: [krallin/tini-images](https://github.com/krallin/tini-images)
- ExoGENI Recipes: [RENCI-NRIG/exogeni-recipes/hadoop](https://github.com/RENCI-NRIG/exogeni-recipes/tree/master/hadoop/hadoop-2)

### What Is Apache Hadoop?

The Apache Hadoop project develops open-source software for reliable, scalable, distributed computing.

The Apache Hadoop software library is a framework that allows for the distributed processing of large data sets across clusters of computers using simple programming models. It is designed to scale up from single servers to thousands of machines, each offering local computation and storage. Rather than rely on hardware to deliver high-availability, the library itself is designed to detect and handle failures at the application layer, so delivering a highly-available service on top of a cluster of computers, each of which may be prone to failures.

See [official documentation](http://hadoop.apache.org) for more information.

## How to use this image

### Build locally


```
$ docker build -t renci/hadoop:2.9.0 ./2.9.0/
  ...
$ docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
renci/hadoop          2.9.0               4a4de8ed48b2        3 minutes ago       1.92GB
...
```

Example `docker-compose.yml` file included that builds from local repository and deploys a single node cluster based on [[1](https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/)].

```
$ docker-compose build
  ...
$ docker-compose up -d
  ...
$ docker-compose ps
 Name               Command               State                                             Ports
--------------------------------------------------------------------------------------------------------------------------------------------
hadoop   /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50070->50070/tcp, 0.0.0.0:50075->50075/tcp, 0.0.0.0:50090->50090/tcp,
                                                  0.0.0.0:8042->8042/tcp, 0.0.0.0:8088->8088/tcp
```

- Port mappings from above:

	```
	ports:
	  - '8042:8042'    # NodeManager web ui
	  - '8088:8088'    # ResourceManager web ui
	  - '50070:50070'  # NameNode web ui 
	  - '50075:50075'  # DataNode web ui
	  - '50090:50090'  # Secondary NameNode web ui
	```

### From Docker Hub

Automated builds are generated at: [https://hub.docker.com/u/renci](https://hub.docker.com/u/renci/dashboard/) and can be pulled as follows.

```
$ docker pull renci/hadoop:2.9.0
```

## Example

Using the provided [`5-node-cluster.yml`](5-node-cluster.yml) file to stand up a five node Hadoop cluster that includes a `namenode`, `resourcemanager` and three workers (`worker1`, `worker2` and `worker3`).

TODO - add diagram

The nodes will use the definitions found in the [site-files](site-files) directory to configure the cluster. These files can be modified as needed to configure your cluster as needed at runtime.

A docker volume named `hadoop-public` is also created to allow the nodes to exchange SSH key information between themselves on startup.

```yaml
version: '3.1'

services:
  namenode:
    image: renci/hadoop:2.9.0
    container_name: namenode
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: namenode
    networks:
      - hadoop
    ports:
      - '50070:50070'
    environment:
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'true'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'false'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 worker3

  resourcemanager:
    image: renci/hadoop:2.9.0
    depends_on:
      - namenode
    container_name: resourcemanager
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: resourcemanager
    networks:
      - hadoop
    ports:
      - '8042:8042'
      - '8088:8088'
    environment:
      IS_NODE_MANAGER: 'true'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'false'
      IS_RESOURCE_MANAGER: 'true'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 worker3

  worker1:
    image: renci/hadoop:2.9.0
    depends_on:
      - namenode
    container_name: worker1
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: worker1
    networks:
      - hadoop
    ports:
      - '50075:50075'
    environment:
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'true'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 worker3

  worker2:
    image: renci/hadoop:2.9.0
    depends_on:
      - namenode
    container_name: worker2
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: worker2
    networks:
      - hadoop
    ports:
      - '50076:50075'
    environment:
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'true'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 worker3

  worker3:
    image: renci/hadoop:2.9.0
    depends_on:
      - namenode
    container_name: worker3
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: worker3
    networks:
      - hadoop
    ports:
      - '50077:50075'
    environment:
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'true'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 worker3

volumes:
  hadoop-public:

networks:
  hadoop:
```

### Start the cluster 

Using `docker-compose`

```
$ docker-compose -f 5-node-cluster.yml up -d
```

After a few moments all containers will be running and should display in a `ps` call.

```
$ docker-compose -f 5-node-cluster.yml ps
     Name                    Command               State                           Ports
-----------------------------------------------------------------------------------------------------------------
namenode          /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50070->50070/tcp
resourcemanager   /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:8042->8042/tcp, 0.0.0.0:8088->8088/tcp
worker1           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50075->50075/tcp
worker2           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50076->50075/tcp
worker3           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50077->50075/tcp
```

Since the ports of the containers were mapped to the host the various web ui's can be observed using a local browser.

**namenode container**: NameNode Web UI on port 50070

NameNode: [http://localhost:50070/dfshealth.html#tab-datanode](http://localhost:50070/dfshealth.html#tab-datanode)

<img width="50%" alt="NameNode" src="https://user-images.githubusercontent.com/5332509/36226272-5546e344-119b-11e8-9076-ca65ae2c0c55.png">

**resource manager container**: ResourceManager/NodeManager Web UI on ports 8088 and 8042

ResourceManger: [http://localhost:8088/cluster](http://localhost:8088/cluster)

<img width="50%" alt="ResourceManager" src="https://user-images.githubusercontent.com/5332509/36226136-fb20dbfe-119a-11e8-8122-625ad2c62a91.png">

NodeManager: [http://localhost:8042/node](http://localhost:8042/node)

<img width="50%" alt="NodeManager" src="https://user-images.githubusercontent.com/5332509/36226239-434059a0-119b-11e8-8c08-d33dd66bfdce.png">

**worker1, worker2 and worker3 containers**: DataNode Web UI on ports 50075, 50076 and 50077

Worker1 DataNode: [http://localhost:50075/datanode.html](http://localhost:50075/datanode.html)

<img width="50%" alt="Worker1 DataManager" src="https://user-images.githubusercontent.com/5332509/36226302-6c3f2fac-119b-11e8-8d90-824c8cd39490.png">

Worker2 DataNode: [http://localhost:50076/datanode.html](http://localhost:50076/datanode.html)

<img width="50%" alt="Worker2 DataManager" src="https://user-images.githubusercontent.com/5332509/36226329-8322fa3c-119b-11e8-8f96-4111eebe0c0e.png">

Worker3 DataNode: [http://localhost:50077/datanode.html](http://localhost:50077/datanode.html)

<img width="50%" alt="Worker3 DataManager" src="https://user-images.githubusercontent.com/5332509/36226346-8fd9fa0a-119b-11e8-9a08-0133c36ed3ee.png">

### Stop the cluster

The cluster can be stopped by issuing a `stop` call.

```
$ docker-compose -f 5-node-cluster.yml stop
Stopping worker2         ... done
Stopping resourcemanager ... done
Stopping worker1         ... done
Stopping worker3         ... done
Stopping namenode        ... done
```

### Restart the cluster

So long as the container definitions have not been removed, the cluster can be restarted by using a `start` call.

```
$ docker-compose -f 5-node-cluster.yml start
Starting namenode        ... done
Starting worker1         ... done
Starting worker3         ... done
Starting worker2         ... done
Starting resourcemanager ... done
```

After a few moments all cluster activity should be back to normal.

### Remove the cluster

The entire cluster can be removed by first stopping it, and then removing the containers from the local machine.

```
$ docker-compose -f 5-node-cluster.yml stop && docker-compose -f 5-node-cluster.yml rm -f
Stopping worker2         ... done
Stopping resourcemanager ... done
Stopping worker1         ... done
Stopping worker3         ... done
Stopping namenode        ... done
Going to remove worker2, resourcemanager, worker1, worker3, namenode
Removing worker2         ... done
Removing resourcemanager ... done
Removing worker1         ... done
Removing worker3         ... done
Removing namenode        ... done
```

### References

1. [https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/](https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/)
2. [https://github.com/RENCI-NRIG/exogeni-recipes/hadoop/hadoop-2/hadoop\_exogeni\_postboot.sh](https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/hadoop/hadoop-2/hadoop_exogeni_postboot.sh)
3. Hadoop configuration files
	- Common: [hadoop-common/core-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/core-default.xml)
	- HDFS: [hadoop-hdfs/hdfs-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)
	- MapReduce: [hadoop-mapreduce-client-core/mapred-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)
	- Yarn: [hadoop-yarn-common/yarn-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
	- Deprecated Properties: [hadoop-common/DeprecatedProperties.html](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
