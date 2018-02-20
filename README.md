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

## Example: Five node cluster

Using the provided [`5-node-cluster.yml`](5-node-cluster.yml) file to stand up a five node Hadoop cluster that includes a `namenode`, `resourcemanager` and three workers (`worker1`, `worker2` and `worker3`).

Hadoop docker network and port mappings (specific network values subject to change based on system):

<img width="80%" alt="Hadoop docker network" src="https://user-images.githubusercontent.com/5332509/36402998-16456864-15b0-11e8-823e-807e434ebab8.png">

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
      - '8088:8088'
    environment:
      IS_NODE_MANAGER: 'false'
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
      - '8042:8042'
      - '50075:50075'
    environment:
      IS_NODE_MANAGER: 'true'
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
      - '8043:8042'
      - '50076:50075'
    environment:
      IS_NODE_MANAGER: 'true'
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
      - '8044:8042'
      - '50077:50075'
    environment:
      IS_NODE_MANAGER: 'true'
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
     Name                    Command               State                            Ports
-------------------------------------------------------------------------------------------------------------------
namenode          /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50070->50070/tcp
resourcemanager   /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:8088->8088/tcp
worker1           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50075->50075/tcp, 0.0.0.0:8042->8042/tcp
worker2           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50076->50075/tcp, 0.0.0.0:8043->8042/tcp
worker3           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50077->50075/tcp, 0.0.0.0:8044->8042/tcp
```

Since the ports of the containers were mapped to the host the various web ui's can be observed using a local browser.

**namenode container**: NameNode Web UI on port 50070

NameNode: [http://localhost:50070/dfshealth.html#tab-datanode](http://localhost:50070/dfshealth.html#tab-datanode)

<img width="50%" alt="NameNode" src="https://user-images.githubusercontent.com/5332509/36226272-5546e344-119b-11e8-9076-ca65ae2c0c55.png">

**resource manager container**: ResourceManager Web UI on port 8088

ResourceManger: [http://localhost:8088/cluster](http://localhost:8088/cluster)

<img width="50%" alt="ResourceManager" src="https://user-images.githubusercontent.com/5332509/36403411-c540a2e6-15b2-11e8-9857-bf5d605d52c7.png">


**worker1, worker2 and worker3 containers**: DataNode Web UI on ports 50075, 50076 and 50077, NodeManager Web UI on ports 8042, 8043 and 8044.

DataNode (worker1): [http://localhost:50075/datanode.html](http://localhost:50075/datanode.html)

<img width="50%" alt="Worker1 DataManager" src="https://user-images.githubusercontent.com/5332509/36226302-6c3f2fac-119b-11e8-8d90-824c8cd39490.png">

NodeManager (worker1): [http://localhost:8042/node](http://localhost:8042/node)

<img width="50%" alt="NodeManager" src="https://user-images.githubusercontent.com/5332509/36226239-434059a0-119b-11e8-8c08-d33dd66bfdce.png">

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

## Example: Map Reduce

**NOTE**: Assumes the existence of the five node cluster from the previous example.

A simple map reduce example has been provided in the [mapreduce-example.sh](mapreduce-example.sh) script.

The script is meant to be run from the host machine and uses `docker exec` to relay commands to the docker `namenode` container as the `hadoop` user.


```
$ ./mapreduce-example.sh
INFO: remove input/output HDFS directories if they already exist
rm: `input': No such file or directory
rm: `output': No such file or directory
INFO: hdfs dfs -mkdir -p /user/hadoop/input
INFO: hdfs dfs -put hadoop/README.txt /user/hadoop/input/
INFO: hadoop jar hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.9.0.jar wordcount input output
18/02/17 19:42:38 INFO client.RMProxy: Connecting to ResourceManager at resourcemanager/172.19.0.5:8032
18/02/17 19:42:39 INFO input.FileInputFormat: Total input files to process : 1
18/02/17 19:42:39 INFO mapreduce.JobSubmitter: number of splits:1
18/02/17 19:42:39 INFO Configuration.deprecation: yarn.resourcemanager.system-metrics-publisher.enabled is deprecated. Instead, use yarn.system-metrics-publisher.enabled
18/02/17 19:42:39 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1518896527275_0001
18/02/17 19:42:40 INFO impl.YarnClientImpl: Submitted application application_1518896527275_0001
18/02/17 19:42:40 INFO mapreduce.Job: The url to track the job: http://resourcemanager:8088/proxy/application_1518896527275_0001/
18/02/17 19:42:40 INFO mapreduce.Job: Running job: job_1518896527275_0001
18/02/17 19:42:51 INFO mapreduce.Job: Job job_1518896527275_0001 running in uber mode : false
18/02/17 19:42:51 INFO mapreduce.Job:  map 0% reduce 0%
18/02/17 19:42:58 INFO mapreduce.Job:  map 100% reduce 0%
18/02/17 19:43:05 INFO mapreduce.Job:  map 100% reduce 100%
18/02/17 19:43:05 INFO mapreduce.Job: Job job_1518896527275_0001 completed successfully
18/02/17 19:43:05 INFO mapreduce.Job: Counters: 49
	File System Counters
		FILE: Number of bytes read=1836
		FILE: Number of bytes written=407057
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		HDFS: Number of bytes read=1480
		HDFS: Number of bytes written=1306
		HDFS: Number of read operations=6
		HDFS: Number of large read operations=0
		HDFS: Number of write operations=2
	Job Counters
		Launched map tasks=1
		Launched reduce tasks=1
		Rack-local map tasks=1
		Total time spent by all maps in occupied slots (ms)=3851
		Total time spent by all reduces in occupied slots (ms)=3718
		Total time spent by all map tasks (ms)=3851
		Total time spent by all reduce tasks (ms)=3718
		Total vcore-milliseconds taken by all map tasks=3851
		Total vcore-milliseconds taken by all reduce tasks=3718
		Total megabyte-milliseconds taken by all map tasks=3943424
		Total megabyte-milliseconds taken by all reduce tasks=3807232
	Map-Reduce Framework
		Map input records=31
		Map output records=179
		Map output bytes=2055
		Map output materialized bytes=1836
		Input split bytes=114
		Combine input records=179
		Combine output records=131
		Reduce input groups=131
		Reduce shuffle bytes=1836
		Reduce input records=131
		Reduce output records=131
		Spilled Records=262
		Shuffled Maps =1
		Failed Shuffles=0
		Merged Map outputs=1
		GC time elapsed (ms)=114
		CPU time spent (ms)=1330
		Physical memory (bytes) snapshot=482201600
		Virtual memory (bytes) snapshot=3950104576
		Total committed heap usage (bytes)=281018368
	Shuffle Errors
		BAD_ID=0
		CONNECTION=0
		IO_ERROR=0
		WRONG_LENGTH=0
		WRONG_MAP=0
		WRONG_REDUCE=0
	File Input Format Counters
		Bytes Read=1366
	File Output Format Counters
		Bytes Written=1306
INFO: hdfs dfs -ls /user/hadoop/output
Found 2 items
-rw-r--r--   2 hadoop supergroup          0 2018-02-17 19:43 /user/hadoop/output/_SUCCESS
-rw-r--r--   2 hadoop supergroup       1306 2018-02-17 19:43 /user/hadoop/output/part-r-00000
INFO: cat hadoop/README.txt
For the latest information about Hadoop, please visit our website at:

   http://hadoop.apache.org/core/

and our wiki, at:

   http://wiki.apache.org/hadoop/

This distribution includes cryptographic software.  The country in
which you currently reside may have restrictions on the import,
possession, use, and/or re-export to another country, of
encryption software.  BEFORE using any encryption software, please
check your country's laws, regulations and policies concerning the
import, possession, or use, and re-export of encryption software, to
see if this is permitted.  See <http://www.wassenaar.org/> for more
information.

The U.S. Government Department of Commerce, Bureau of Industry and
Security (BIS), has classified this software as Export Commodity
Control Number (ECCN) 5D002.C.1, which includes information security
software using or performing cryptographic functions with asymmetric
algorithms.  The form and manner of this Apache Software Foundation
distribution makes it eligible for export under the License Exception
ENC Technology Software Unrestricted (TSU) exception (see the BIS
Export Administration Regulations, Section 740.13) for both object
code and source code.

The following provides more details on the included cryptographic
software:
  Hadoop Core uses the SSL libraries from the Jetty project written
by mortbay.org.
INFO: hdfs dfs -cat /user/hadoop/output/part-r-00000
(BIS),	1
(ECCN)	1
(TSU)	1
(see	1
5D002.C.1,	1
740.13)	1
<http://www.wassenaar.org/>	1
Administration	1
Apache	1
BEFORE	1
BIS	1
Bureau	1
Commerce,	1
Commodity	1
Control	1
Core	1
Department	1
ENC	1
Exception	1
Export	2
For	1
Foundation	1
Government	1
Hadoop	1
Hadoop,	1
Industry	1
Jetty	1
License	1
Number	1
Regulations,	1
SSL	1
Section	1
Security	1
See	1
Software	2
Technology	1
The	4
This	1
U.S.	1
Unrestricted	1
about	1
algorithms.	1
and	6
and/or	1
another	1
any	1
as	1
asymmetric	1
at:	2
both	1
by	1
check	1
classified	1
code	1
code.	1
concerning	1
country	1
country's	1
country,	1
cryptographic	3
currently	1
details	1
distribution	2
eligible	1
encryption	3
exception	1
export	1
following	1
for	3
form	1
from	1
functions	1
has	1
have	1
http://hadoop.apache.org/core/	1
http://wiki.apache.org/hadoop/	1
if	1
import,	2
in	1
included	1
includes	2
information	2
information.	1
is	1
it	1
latest	1
laws,	1
libraries	1
makes	1
manner	1
may	1
more	2
mortbay.org.	1
object	1
of	5
on	2
or	2
our	2
performing	1
permitted.	1
please	2
policies	1
possession,	2
project	1
provides	1
re-export	2
regulations	1
reside	1
restrictions	1
security	1
see	1
software	2
software,	2
software.	2
software:	1
source	1
the	8
this	3
to	2
under	1
use,	2
uses	1
using	2
visit	1
website	1
which	2
wiki,	1
with	1
written	1
you	1
your	1
HDFS directories at: http://localhost:50070/explorer.html#/user/hadoop
```

NameNode: [http://localhost:50070/explorer.html#/user/hadoop](http://localhost:50070/explorer.html#/user/hadoop)

<img width="50%" alt="MapReduce Example" src="https://user-images.githubusercontent.com/5332509/36345032-c4957f5a-13f1-11e8-95a1-6fadb9988157.png">

### References

1. [https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/](https://tecadmin.net/setup-hadoop-single-node-cluster-on-centos-redhat/)
2. [https://github.com/RENCI-NRIG/exogeni-recipes/hadoop/hadoop-2/hadoop\_exogeni\_postboot.sh](https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/hadoop/hadoop-2/hadoop_exogeni_postboot.sh)
3. Hadoop configuration files
	- Common: [hadoop-common/core-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/core-default.xml)
	- HDFS: [hadoop-hdfs/hdfs-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)
	- MapReduce: [hadoop-mapreduce-client-core/mapred-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)
	- Yarn: [hadoop-yarn-common/yarn-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
	- Deprecated Properties: [hadoop-common/DeprecatedProperties.html](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
4. Example MapReduce: [https://tecadmin.net/hadoop-running-a-wordcount-mapreduce-example/](https://tecadmin.net/hadoop-running-a-wordcount-mapreduce-example/)
