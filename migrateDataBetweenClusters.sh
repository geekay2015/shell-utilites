#!/bin/bash
# ------------------------------------------------------------------
# Script name   :  migrateDataBetweenClusters.sh
# VERSION       :	1.0
# usage         : migrateDataBetweenClusters.sh
# ------------------------------------------------------------------
# Purpose:
#               Migrate hive data and metadata
#               Ensure that metadata is updated based on the target clusters Hive metastore version
# ------------------------------------------------------------------
# Author:	Gangadhar Kadam
# ------------------------------------------------------------------
# Revision history:
# 2018-05-30  Created
# ------------------------------------------------------------------

# On old cluster

# Check all the directories you need to copy
hdfs dfs -ls /apps/hive/warehouse

# Identify the data to be copied over
hdfs dfs -ls /tmp/tpch-generate/2

# check the size of the data
hdfs dfs -du -s -h /tmp/tpch-generate/2

# Identify the metastore database server and dump the hive metadata database
mysqldump hive -u hive -p > hive.dump

# On the new cluster
hadoop distcp -D ipc.client.fallback-to-simple-auth-allowed=true hdfs://nn1:8020/foo/bar hdfs://nn2:8020/bar/foo

# Validate if the data has been copied over succesfully
hdfs dfs -ls /tmp/tpch-generate/2

# Stop the Metastore Process
# Restore the backup from old clusters hive.dump to mysql database
mysql -u hive -D hive -p < /tmp/hive.dump 

# Because the hive dump was obtained from old cluster, it still might have the old hdfs location(s) for tables, partitions, 
# metatool command to update the location
export HIVE_CONF_DIR=/etc/hive/2.5.3.0-37/0/conf.server; 
hive --service metatool -updateLocation hdfs://xlnode-standalone.hwx.com:8020 hdfs://xlnode-3.hwx.com:8020 -tablePropKey avro.schema.url -serdePropKey avro.schema.url

# perform the metastore upgrade as the dump was obtained from old cluster and 
# there, are/may have, additional objects which were introduced in the new version
cd /usr/hdp/2.5.3.0-37/hive2/bin/ && export HIVE_CONF_DIR=/etc/hive/conf/conf.server; ./schematool -dbType mysql -upgradeSchema --verbose

cat /usr/hdp/2.5.3.0-37/hive2/scripts/metastore/upgrade/mysql/upgrade-2.0.0-to-2.1.0.mysql.sql

# Run the upgradeSchema command again and you should see an output similar to this upon completion
cd /usr/hdp/2.5.3.0-37/hive2/bin/ && export HIVE_CONF_DIR=/etc/hive/conf/conf.server; ./schematool -dbType mysql -upgradeSchema --verbose

# Restart the Metastore Process via Ambari and validate bother version and data for tables
