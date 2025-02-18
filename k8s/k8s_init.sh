
# 配置变量
CLUSTER_NAME=$1
PWD="/etc/kubeasz"
KUBE_DIR=$PWD/clusters/$CLUSTER_NAME

# 初始化
$PWD//ezctl new $CLUSTER_NAME
if [[ $? -ne 0 ]];then
    echo "cluster name [${CLUSTER_NAME}] was exist in ${PWD}/clusters/${CLUSTER_NAME}."
    exit 1
fi

# 修改二进制安装脚本配置 config.yml
sed -ri "s+^(CLUSTER_NAME:).*$+\1 \"${CLUSTER_NAME}\"+g" $KUBE_DIR/config.yml

# 离线安装
sed -ri "s+^(INSTALL_SOURCE:).*$+\1 \"offline\"+g" $KUBE_DIR/config.yml

# docker data dir
DOCKER_STORAGE_DIR="/var/lib/container/docker"
sed -ri "s+^(DOCKER_STORAGE_DIR:).*$+DOCKER_STORAGE_DIR: \"${DOCKER_STORAGE_DIR}\"+g" $KUBE_DIR/config.yml

# containerd data dir
CONTAINERD_STORAGE_DIR="/var/lib/container/containerd"
sed -ri "s+^(CONTAINERD_STORAGE_DIR:).*$+CONTAINERD_STORAGE_DIR: \"${CONTAINERD_STORAGE_DIR}\"+g" $KUBE_DIR/config.yml

# kubelet logs dir
KUBELET_ROOT_DIR="/var/lib/container/kubelet"
sed -ri "s+^(KUBELET_ROOT_DIR:).*$+KUBELET_ROOT_DIR: \"${KUBELET_ROOT_DIR}\"+g" $KUBE_DIR/config.yml

# [docker]信任的HTTP仓库
sed -ri "s+127.0.0.1/8+172.18.1.0/24+g" $KUBE_DIR/config.yml

# node节点最大pod 数
MAX_PODS="120"
sed -ri "s+^(MAX_PODS:).*$+\1 ${MAX_PODS}+g" $KUBE_DIR/config.yml

# disable dashboard auto install
sed -ri "s+^(dashboard_install:).*$+\1 \"no\"+g" $KUBE_DIR/config.yml

# 容器运行时
sed -ri "s+^CONTAINER_RUNTIME=.*$+CONTAINER_RUNTIME=\"docker\"+g" $KUBE_DIR/hosts

# docker 版本
echo "DOCKER_VER=20.10.9" >> $KUBE_DIR/hosts