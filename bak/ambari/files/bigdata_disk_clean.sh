#!/bin/bash

# 如果是输入的日期按照取输入日期；如果没输入日期取当前时间的前3天
if [ -n "$1" ] ;then
   do_date=$1
else
   do_date=`date -d "-4 day" +%Y%m%d`
fi

# 清理wshoto
partition_clear() {
if echo $1 | grep -q -E '_df$'
 then
 hadoop fs -rmr -skipTrash /warehouse/tablespace/external/hive/wshoto.db/$1/ds=$do_date
fi
}

hive -e "use wshoto;show tables" | while read line
do
 table_name=`echo $line | awk -F ' ' '{print $2," "}' | sed s/[[:space:]]//g`
 if [[ $table_name == ods||$table_name == dwd||$table_name == dim* ]];
 then
  partition_clear "$table_name"
 fi
done

# 服务器组件日志
ssh hdp101 "rm -rf /hadoop/yarn/local/usercache/*"
ssh hdp102 "rm -rf /hadoop/yarn/local/usercache/*"
ssh hdp103 "rm -rf /hadoop/yarn/local/usercache/*"
ssh hdp101 "rm -rf /hadoop/yarn/log/*"
ssh hdp102 "rm -rf /hadoop/yarn/log/*"
ssh hdp103 "rm -rf /hadoop/yarn/log/*"
ssh hdp101 "rm -rf /var/log/hadoop/hdfs/*"
ssh hdp102 "rm -rf /var/log/hadoop/hdfs/*"
ssh hdp103 "rm -rf /var/log/hadoop/hdfs/*"

# hdfs日志
hadoop fs -rmr -skipTrash /app-logs/root/logs/*
hadoop fs -rmr -skipTrash /spark2-history/*
