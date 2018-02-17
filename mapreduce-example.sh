#/usr/bin/env bash

echo 'INFO: remove input/output HDFS directories if they already exist'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -rm -R input'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -rm -R output'

echo 'INFO: hdfs dfs -mkdir -p /user/hadoop/input'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -mkdir -p /user/hadoop/input'

echo 'INFO: hdfs dfs -put hadoop/README.txt /user/hadoop/input/'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -put hadoop/README.txt /user/hadoop/input/'

echo 'INFO: hadoop jar hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.9.0.jar wordcount input output'
docker exec namenode runuser -l hadoop -c $'hadoop jar hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.9.0.jar wordcount input output'

echo 'INFO: hdfs dfs -ls /user/hadoop/output'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -ls /user/hadoop/output'

echo 'INFO: cat hadoop/README.txt'
docker exec namenode runuser -l hadoop -c $'cat hadoop/README.txt'

echo 'INFO: hdfs dfs -cat /user/hadoop/output/part-r-00000'
docker exec namenode runuser -l hadoop -c $'hdfs dfs -cat /user/hadoop/output/part-r-00000'

echo 'HDFS directories at: http://localhost:50070/explorer.html#/user/hadoop'

exit 0;
