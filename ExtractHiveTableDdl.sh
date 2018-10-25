#!/bin/bash
# ------------------------------------------------------------------
# Script name:  ExtractHiveTableDdl.sh
# VERSION:	1.0
# usage:        ExtractHiveTableDdl.sh
# ------------------------------------------------------------------
# Purpose:
#               1. extract the DDLs for all tables and partition in a given hive database. 
#               This scripts comes handy when migrating/creating Hive Tables from one cluster to another.
# ------------------------------------------------------------------
# Author:	Gangadhar Kadam
# ------------------------------------------------------------------
# Revision history:
# 2018-05-30  Created
# ------------------------------------------------------------------
hiveDBName=testdbname;
 
showcreate="show create table "
showpartitions="show partitions "
terminate=";"
 
tables=`hive -e "use $hiveDBName;show tables;"`
tab_list=`echo "${tables}"`
 
rm -f ${hiveDBName}_all_table_partition_DDL.txt
 
for list in $tab_list
do
   showcreatetable=${showcreatetable}${showcreate}${list}${terminate}
   listpartitions=`hive -e "use $hiveDBName; ${showpartitions}${list}"`
 
   for tablepart in $listpartitions
   do
      partname=`echo ${tablepart/=/=\"}`
      echo $partname
      echo "ALTER TABLE $list ADD PARTITION ($partname\");" >> ${hiveDBName}_all_table_partition_DDL.txt
   done
 
done
 
echo " ====== Create Tables ======= : " $showcreatetable
 
## Remove the file
rm -f ${hiveDBName}_extract_all_tables.txt
 
hive -e "use $hiveDBName; ${showcreatetable}" >> ${hiveDBName}_extract_all_tables.txt
