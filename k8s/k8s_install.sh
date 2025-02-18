#!/bin/bash
set -o nounset
set -o errexit

# 配置变量
CLUSTER_NAME=ws
PWD="/etc/kubeasz"

# 配置K8S的ETCD数据备份的定时任务
# if cat /etc/redhat-release &>/dev/null;then
#     if ! grep -w '94.backup.yml' /var/spool/cron/root &>/dev/null;then echo "00 00 * * * `which ansible-playbook` ${PWD}/playbooks/94.backup.yml &> /dev/null" >> /var/spool/cron/root;else echo exists ;fi
#     chown root.crontab /var/spool/cron/root
#     chmod 600 /var/spool/cron/root
# else
#     if ! grep -w '94.backup.yml' /var/spool/cron/crontabs/root &>/dev/null;then echo "00 00 * * * `which ansible-playbook` ${PWD}/playbooks/94.backup.yml &> /dev/null" >> /var/spool/cron/crontabs/root;else echo exists ;fi
#     chown root.crontab /var/spool/cron/crontabs/root
#     chmod 600 /var/spool/cron/crontabs/root
# fi
# rm /var/run/cron.reboot
# service crond restart 

#---------------------------------------------------------------------------------------------------
# 准备开始安装了
cd ${PWD}/

# 01-建证书和环境准备
${PWD}/ezctl setup $CLUSTER_NAME 01
sleep 10
# 02-安装etcd集群
${PWD}/ezctl setup $CLUSTER_NAME 02
sleep 10
# 03-安装容器运行时
${PWD}/ezctl setup $CLUSTER_NAME 03
sleep 10
# 04-安装master节点
${PWD}/ezctl setup $CLUSTER_NAME 04
sleep 10
# 05-安装node节点
${PWD}/ezctl setup $CLUSTER_NAME 05
sleep 10
# 06-安装集群网络
${PWD}/ezctl setup $CLUSTER_NAME 06
sleep 10
# 07-安装集群插件
${PWD}/ezctl setup $CLUSTER_NAME 07
sleep 1


k8s_bin_path='/etc/kubeasz/bin'


echo "-------------------------  k8s version list  ---------------------------"
${k8s_bin_path}/kubectl version
echo
echo "-------------------------  All Healthy status check  -------------------"
${k8s_bin_path}/kubectl get componentstatus
echo
echo "-------------------------  k8s cluster info list  ----------------------"
${k8s_bin_path}/kubectl cluster-info
echo
echo "-------------------------  k8s all nodes list  -------------------------"
${k8s_bin_path}/kubectl get node -o wide
echo
echo "-------------------------  k8s all-namespaces's pods list   ------------"
${k8s_bin_path}/kubectl get pod --all-namespaces
echo
echo "-------------------------  k8s all-namespaces's service network   ------"
${k8s_bin_path}/kubectl get svc --all-namespaces
echo
echo "-------------------------  k8s welcome for you   -----------------------"
echo