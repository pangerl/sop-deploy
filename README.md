# SOP标准化部署工具

项目致力于提供快速部署产品；基于二进制方式部署k8s集群

## 准备工作

- 上传部署包`sop-deploy`到部署机器

```shell
# 这里放到了 root 的家目录
# 解压部署包
```

### 安装 ansible

#### 修改 hosts 文件

**按照规划修改 ansible 的 hosts 文件（重要）**

```ini
# sop-deploy/ansible/hosts
[k8s]
172.18.1.5 hostname=node-1
172.18.1.6 hostname=node-2
172.18.1.7 hostname=node-3
172.18.1.8 hostname=node-4
[hdp]
172.18.1.15
172.18.1.3
172.18.1.14
[middle]
172.18.1.17
172.18.1.2 
[node:children]
hdp
middle
[redis]
172.18.1.17
...
[all:vars]
ansible_ssh_user=root
ansible_ssh_pass=xxx
ansible_ssh_port=22
```

#### 本地yum源（纯内网，yum无法使用的情况）

```shell
# 上传iso镜像，例如：CentOS-7-x86_64-DVD-2009.iso
# 下载地址，见 sop-deploy/packages/README.md
# 这里上传到 /data/iso/ 目录下
# ls /data/iso/CentOS-7-x86_64-DVD-2009.iso
# 执行安装啊本
sh /data/sop-deploy/tools/update_repo_local.sh
```

#### 安装 ansible

```shell
[root@VM-0-17-centos ~]# cd sop-deploy/ansible && sh install_ansible.sh
参数个数不够, 请按照如下格式传入参数
Usage:
install_ansible.sh [-o] '离线安装'
install_ansible.sh [-y] '在线安装'
install_ansible.sh [-h] '帮助'
# 这里离线部署
[root@VM-1-15-centos ansible]# sh install_ansible.sh -o
[root@VM-1-15-centos ansible]# ansible --version
ansible 2.10.7
  config file = /tmp/sop-deploy/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/lib/python3.7/site-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 3.7.9 (default, Jun  7 2022, 15:24:33) [GCC 4.8.5 20150623 (Red Hat 4.8.5-44)]
```

#### 挂载数据盘

```shell
# 根据实际情况修改 mount_disk.sh、k8s_mount_disk.sh 脚本
cd /root/sop-install/ansible
ansible node -m script -a 'mount_disk.sh'
# 注意 k8s 集群的数据盘挂载跟其他机器不同
ansible k8s -m script -a 'k8s_mount_disk.sh'
```

#### 上传数据包

- 将项目部署包迁移到部署目录，默认为 `/data/sop-deploy`，对应配置文件中的变量：`base_dir`

```shell
mv /root/sop-deploy /data/sop-deploy
# ls /data/sop-deploy/
```

- 上传 `kubeasz.tgz` 到部署机器，解压

```shell
# 从 COS 上下载 kubeasz.tgz，然后放到部署机的 /etc 目录下,并解压
cd /etc && tar zxf kubeasz.tgz
# ls kubeasz/
ansible.cfg  bin  clusters  docs  down  example  ezctl  ezdown  manifests  pics  playbooks  README.md  roles  tools
```

- 上传安装包到项目目录下（根据需要下载安装包，非常重要）

```shell
# 从 COS 上下载整理好的数据包，上传到部署机器的数据目录下
# 大数据包、二进制包、中间件镜像、kubeasz
# 参考 README.md
[root@localhost packages]# ls
binary_tag  hadoop  middle_img  README.md  sql
```

#### ## 部署中间件

### 安装 docker

为非 k8s 节点，部署docker服务

```
cd /data/sop-deploy
# 执行前手动修改 playbooks/03.runtime.yml 文件，默认：middle
ansible-playbook -e @config.yml playbooks/03.runtime.yml
# 使用 --limit 参数可手动指定执行机器
# ansible-playbook -e @config.yml playbooks/03.runtime.yml --limit 172.18.1.3
```

**修改检查配置文件**

```ini
# cat config.yml
# single/replication/cluster
REDIS_MODEL: "single"
PG_MODEL: "single"
MQ_MODEL: "single"
DELAY_MODEL: "single"
# [docker]信任的HTTP仓库
INSECURE_REG: '["172.18.1.0/24"]'
```

### redis

```shell
ansible-playbook -e @config.yml playbooks/04.redis.yml
# 调试
# docker run -it --rm --network redis-tier bitnami/redis:7.0.0 redis-cli -h redis -a xxxxxx2 info replication
```

### postgres

```shell
ansible-playbook -e @config.yml playbooks/05.postgres.yml
# 调试
# docker run -it --rm --network pg-tier -e PGPASSWORD='xxxxxx2' bitnami/postgresql:11.16.0 psql -h postgres -U postgres
postgres=# show max_connections;
 max_connections
-----------------
 2000
(1 row)
postgres=# select client_addr,sync_state from pg_stat_replication;
 client_addr  | sync_state
--------------+------------
 192.168.7.71 | async
(1 row)
```

### kafka

```shell
# 单节点
ansible-playbook -e @config.yml playbooks/06.kafka-single.yml
# 集群
ansible-playbook -e @config.yml playbooks/06.kafka-cluster.yml
# 调试
# http://172.18.1.17:9000/
# systemctl status zookeeper
# systemctl status kafka
```

### rocketmq

```shell
ansible-playbook -e @config.yml playbooks/07.rocketmq.yml
# 调试
# http://172.18.1.17:8081/#/
```

### elasticsearch

```shell
# 单节点
ansible-playbook -e @config.yml playbooks/08.elasticsearch-single.yml
# 集群
ansible-playbook -e @config.yml playbooks/08.elasticsearch-cluster.yml
# 调试
# http://172.18.1.17:5601/
# curl -XGET "http://172.18.1.15:9200/_cluster/health?pretty" -H 'Content-Type: application/json' -u elastic:xxxxxx2
```

### delay-message

依赖 mysql，和 rocketmq，请提前准备好。mysql 可使用下面的一键脚本。

```shell
ansible-playbook -e @config.yml playbooks/09.delay-message.yml
# 715
ansible-playbook -e @config.yml playbooks/09.delay-message-715.yml
# 调试
# [root@VM-1-17-centos ~]# curl -X POST http://172.18.1.17:8601/peer/leader
{"code":"00000","msg":"OK","data":"{\"empty\":false,\"endpoint\":{\"ip\":\"172.18.1.17\",\"port\":8802},\"idx\":0,\"ip\":\"172.18.1.17\",\"port\":8802,\"priority\":-1,\"priorityDisabled\":true,\"priorityNotElected\":false}"}
# curl -X POST http://172.18.1.17:8601/peer/storage/num
{"code":"00000","msg":"OK","data":"0"}
```

### fastdfs(可选)

```shell
ansible-playbook -e @config.yml playbooks/11.fastdfs.yml
# 调试
# docker exec -it storage bash
# cd /bin/ && echo 'hello' > hello.txt && fdfs_test /etc/fdfs/client.conf upload hello.txt
# http://172.18.1.17:8080/group1/M00/00/00/rBIBEWK-10KAdAXwAAAABjY6MCA797_big.txt
```

### nginx

```shell
ansible-playbook -e @config.yml playbooks/12.nginx.yml
```

## 大数据

### mysql

```shell
ansible-playbook -e @config.yml playbooks/13.mysql.yml
# 调试
docker run -it --rm --network mysql-tier bitnami/mysql:5.7.38 mysql -h mysql -u root -pxxxxxx2
```

### ambari(集群)

```shell
ansible-playbook -e @config.yml playbooks/14.ambari.yml
```

### azkaban(调度器)

```shell
ansible-playbook -e @config.yml playbooks/15.azkaban.yml
# 注意部署完成后，还需要通过web管理页面创建hdp集群
```

### spark(可选，单机版，基本不用)

```shell
ansible-playbook -e @config.yml playbooks/16.spark.yml
```

## 数据初始化

## 服务检查

```shell
ansible-playbook -e @config.yml playbooks/20.check-svc.yml
```

## 部署 k8s 集群

### 修改主机名（重要）

```
ansible-playbook -e @config.yml playbooks/02.modify_hostname.yml
# 编辑 add_host.sh
# 同步 /etc/hosts
ansible k8s -m script -a 'add_host.sh'
```

### 创建集群配置（跳过）

```shell
cd /data/sop-deploy/k8s
sh k8s_init.sh ws
```

### 修改配置

```shell
# /etc/kubeasz/clusters/ws/hosts
[etcd]
172.18.1.6
[kube_master]
172.18.1.6
[kube_node]
172.18.1.6
172.18.1.11
# /etc/kubeasz/clusters/ws/config.yml
# [docker]信任的HTTP仓库,修改成宿主机的网段
INSECURE_REG: '["172.18.1.0/24"]'
```

### 开始部署

```shell
# 确保 /etc/kubeasz 部署文件已经准备
cd /data/sop-deploy/k8s
sh k8s_install.sh
# etcd 备份与恢复
# ezctl backup ws
# ezctl restore ws
# 增加 node 节点
# 新增之前，需要配置免密登陆
ansible 192.168.x.x -m authorized_key -a "user=root exclusive=true manage_dir=true key='$(</root/.ssh/authorized_keys)'"
# ezctl add-node 192.168.x.x
```

## 依赖组件

### 部署 kuboard

```shell
ansible-playbook -e @config.yml playbooks/01.kuboard.yml
# 调试
http://172.18.0.17:8080
```

### 部署 skywalking

```shell
ansible-playbook -e @config.yml playbooks/21.skywalking.yml
# 检查 skywalking 的安装进度
helm list -n prod-service
kubectl get pod -n prod-service |grep sky
```
