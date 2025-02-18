#!/bin/bash

## k8s上日志及容器数据存独立磁盘步骤
mkdir -p /var/lib/{kubelet,docker,container}

# 格式化磁盘
mkfs.xfs -n ftype=1 /dev/vdb -f

# 挂载磁盘
mount /dev/vdb /var/lib/container
mkdir -p /var/lib/container/{kubelet,docker}
mount --bind /var/lib/container/kubelet /var/lib/kubelet
mount --bind /var/lib/container/docker /var/lib/docker

# 永久挂载
echo '/dev/vdb /var/lib/container/ xfs  defaults 0 0' >> /etc/fstab
echo '/var/lib/container/kubelet /var/lib/kubelet none defaults,bind 0 0' >> /etc/fstab
echo '/var/lib/container/docker /var/lib/docker none defaults,bind 0 0' >> /etc/fstab

# 检查挂载
df -Th