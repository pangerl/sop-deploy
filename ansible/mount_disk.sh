#!/bin/bash

# 创建data 目录
[ ! -d "/data" ] && mkdir /data

# 格式化磁盘
mkfs.xfs -n ftype=1 /dev/vdb -f

# 挂载磁盘
mount /dev/vdb /data

# 永久挂载
echo '/dev/vdb /data xfs  defaults 0 0' >> /etc/fstab

# 检查挂载
df -Th