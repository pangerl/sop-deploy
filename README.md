# SOP 标准化部署工具

本项目致力于提供微盛产品的快速标准化部署能力，主要基于 Ansible 和 Docker 进行自动化部署。

## 目录

1. [准备工作 (Prerequisites)](#1-准备工作-prerequisites)
2. [基础环境 (Infrastructure)](#2-基础环境-infrastructure)
3. [中间件部署 (Middleware)](#3-中间件部署-middleware)
4. [配置说明 (Configuration)](#4-配置说明-configuration)

---

## 1. 准备工作 (Prerequisites)

### 1.1 资源准备

请参考 `packages/README.md` 获取所需安装包下载地址。
- **SOP 部署包**: 上传到部署机器（默认为 `/data/sop-deploy`）。
- **Ansible 离线包**: 用于离线安装 Ansible。
- **中间件镜像**: Docker 镜像包。
- **二进制包**: Java, Redis, 等二进制文件。

### 1.2 环境初始化

#### (1) 安装 Ansible

进入 `ansible` 目录执行安装脚本：

```shell
cd sop-deploy/ansible
# 离线安装
sh install_ansible.sh -o
# 在线安装
# sh install_ansible.sh -y
# 验证
ansible --version
```

#### (2) 配置 hosts 文件

修改 `ansible/hosts` 文件，规划服务器角色。

> [!NOTE]
> 请根据实际网络环境修改 IP 地址和主机名。

```ini
[k8s]
172.18.1.5 hostname=node-1
172.18.1.6 hostname=node-2

[hdp]
172.18.1.15
172.18.1.3

[middle]
172.18.1.17
172.18.1.2

# 中间件分组
[redis]
172.18.1.17

[mysql]
172.18.1.17

[all:vars]
ansible_ssh_user=root
ansible_ssh_pass=YourPassword
ansible_ssh_port=22
```

#### (3) 基础配置与挂载

```shell
# 1. 修改主机名
ansible-playbook -e @config.yml playbooks/02.modify_hostname.yml

# 2. 挂载数据盘 (根据实际情况修改 ansible/mount_disk.sh)
cd ansible
ansible middle -m script -a 'mount_disk.sh'
```

---

## 2. 基础环境 (Infrastructure)

### 2.1 依赖与运行时

```shell
# 部署 Docker 及基础环境
ansible-playbook -e @config.yml playbooks/03.runtime.yml

# 时间同步 (Chrony)
ansible-playbook -e @config.yml playbooks/25.chrony.yml
```

### 2.2 Kubernetes 集群 (Kubeasz)

如果需要部署 K8s 集群：

```shell
# 1. 准备 kubeasz 离线包
cp kubeasz.tgz /etc/ && cd /etc && tar zxf kubeasz.tgz

# 2. 初始化集群配置 (以 cluster-name=ws 为例)
cd /data/sop-deploy/k8s
sh k8s_init.sh ws

# 3. 安装集群
sh k8s_install.sh
```

### 2.3 监控与管理

- **Kuboard**: K8s 管理面板
  ```shell
  ansible-playbook -e @config.yml playbooks/22.kuboard.yml
  ```
- **Nightingale (夜莺监控)**:
  ```shell
  # 部署 Categraf 采集器
  ansible-playbook -e @config.yml playbooks/31.categraf.yml
  # 部署 Nightingale 服务端
  ansible-playbook -e @config.yml playbooks/32.nightingale.yml
  # 边缘节点 (Optional)
  ansible-playbook -e @config.yml playbooks/38.n9e-edge.yml
  ```
- **上传监控**:
  ```shell
  ansible-playbook -e @config.yml playbooks/33.upload-monitor.yml
  ```

---

## 3. 中间件部署 (Middleware)

所有部署均需在 `config.yml` 中配置相应的模式（单机/集群）。

### 3.1 数据库 (Databases)

- **Redis**:
  ```shell
  ansible-playbook -e @config.yml playbooks/04.redis.yml
  ```
- **PostgreSQL**:
  ```shell
  ansible-playbook -e @config.yml playbooks/05.postgres.yml
  ```
- **MySQL**:
  ```shell
  ansible-playbook -e @config.yml playbooks/13.mysql.yml
  ```
- **Doris (OLAP)**:
  ```shell
  # 物理机部署
  ansible-playbook -e @config.yml playbooks/34.doris.yml
  # Docker 部署
  ansible-playbook -e @config.yml playbooks/40.doris-docker.yml
  ```

### 3.2 消息队列 (Message Queues)

- **RocketMQ**:
  ```shell
  ansible-playbook -e @config.yml playbooks/07.rocketmq.yml
  ```

### 3.3 服务治理 (Service Governance)

- **Nacos**:
  ```shell
  ansible-playbook -e @config.yml playbooks/28.nacos.yml
  ```
- **XXL-JOB**:
  ```shell
  ansible-playbook -e @config.yml playbooks/30.xxl-job.yml
  ```

### 3.4 存储与搜索 (Storage & Search)

- **Elasticsearch**:
  ```shell
  # 单节点
  ansible-playbook -e @config.yml playbooks/08.elasticsearch-single.yml
  # 集群
  ansible-playbook -e @config.yml playbooks/08.elasticsearch-cluster.yml
  ```
- **MinIO**:
  ```shell
  ansible-playbook -e @config.yml playbooks/40.minio.yml
  ```
- **FastDFS**:
  ```shell
  ansible-playbook -e @config.yml playbooks/11.fastdfs.yml
  ```

### 3.5 其他服务

- **Nginx**:
  ```shell
  ansible-playbook -e @config.yml playbooks/12.nginx.yml
  ```
- **延迟消息服务 (Delay Message)**:
  ```shell
  ansible-playbook -e @config.yml playbooks/09.delay-message.yml
  ```

---

## 4. 配置说明 (Configuration)

文件位置: `config.yml`

| 变量名 | 说明 | 可选值 |
| :--- | :--- | :--- |
| `REDIS_MODEL` | Redis 模式 | `single` (单机) |
| `PG_MODEL` | PostgreSQL 模式 | `single` (单机) |
| `MySQL_MODEL` | MySQL 模式 | `single` (单机) |
| `NACOS_MODEL` | Nacos 模式 | `single` (单机), `cluster` (集群) |
| `XXL_JOB_MODEL` | XXL-JOB 模式 | `single` (单机) |
| `DORIS_MODEL` | Doris 模式 | `single` (单机) |
| `ES_MODEL` | Elasticsearch 模式 | `single` (单机) |
| `MINIO_MODEL` | MinIO 模式 | `single` (单机) |
| `INSECURE_REG` | 信任的 HTTP 镜像仓库网段 | e.g. `["172.18.1.0/24"]` |
| `limit_memory` | Java 内存限制 | e.g. `4096m` |

> [!IMPORTANT]
> 部署前请务必确认 `config.yml` 中的配置与您的 `hosts` 规划一致。
