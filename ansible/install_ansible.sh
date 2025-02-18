#!/bin/bash
set -o nounset
set -o errexit

# get work directory
GlobalDir=$(cd "$(dirname "$0")" || exit; pwd)

# 安装用户，默认 root
# SshUser=`cat $GlobalDir/global_config.yml | grep 'user:' | awk '{print $2}'|head -1`
SshUser=$USER

# 操作系统，可选 centos|openEuler|kylin
OS=centos

if [ "$SshUser" = "root" ];then
    exec=""
else
    exec=sudo
    sudo chown -R $SshUser.$SshUser $GlobalDir
fi

# 认证配置
function check_ansible()
{
    # 查看 ansible 安装结果
    ansible --version
    # 创建配置文件
    if [ "$SshUser" != "root" ];then
        $exec sed -i 's/.*remote_user =.*/remote_user = '$SshUser'/g' /etc/ansible/ansible.cfg
        $exec sed -i 's/.*become=.*/become=True/g' /etc/ansible/ansible.cfg
        $exec sed -i 's/.*become_method=.*/become_method=sudo/g' /etc/ansible/ansible.cfg
    fi

    if [ -f /etc/ansible/hosts ];then
        $exec ln -sf $GlobalDir/hosts /etc/ansible/hosts
    fi
    # ansible-galaxy collection download community.docker -p .
    # ansible-galaxy collection install $GlobalDir/rpm/community/community-docker-2.6.0.tar.gz --ignore-errors
    ansible-galaxy collection install $GlobalDir/rpm/community/community-general-8.6.0.tar.gz

    # 生成公私钥
    # ssh-keygen -m PEM -t rsa -C `ip a|grep inet|grep -Ev '127.0.0.1|inet6|docker0|virbr'|awk '{print $2}'|head -1|cut -d '/' -f 1` -P "" -f ~/.ssh/id_rsa
    # cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    # 分发密钥
    # ansible all -m authorized_key -a "user=root exclusive=true manage_dir=true key='$(</root/.ssh/authorized_keys)'"
    # 测试
    ansible all -m ping
}


# 安装python3
function python3_install()
{
    if [ ! -f /usr/bin/unzip ];then
        $exec rpm -ivh $GlobalDir/rpm/$OS/unzip-6.0-22.el7_9.x86_64.rpm
    fi
    if [ ! -d /usr/local/python3 ];then
        $exec unzip -oq $GlobalDir/python3.zip -d /usr/local
        if [ "$SshUser" != "root" ];then
            $exec chown -R $SshUser.$SshUser /usr/local/python3
        fi
    fi
}

# 离线安装
function offline_install()
{
    if [ ! -f /usr/bin/ansible ];then
        cd $GlobalDir/rpm/$OS/
        $exec yum localinstall *.rpm -y
        $exec sed -i 's/.*host_key_checking.*/host_key_checking = False/g' /etc/ansible/ansible.cfg
        $exec sed -i 's#.*log_path.*#log_path = /var/log/ansible.log#g' /etc/ansible/ansible.cfg
        $exec touch /var/log/ansible.log
        $exec chmod 777 /var/log/ansible.log
    fi
}

# 在线安装
function oneline_install()
{
    $exec yum update -y
    # $exec yum install epel-release -y
    $exec yum install -y ansible gcc-c++ gcc wget vim lrzsz telnet rsync sshpass
}

# 使用方法
function usage() {
    echo -e "Usage: 推荐离线" 1>&2
    echo -e "$0 [-o] '离线安装'"
    echo -e "$0 [-y] '在线安装'"
    echo -e "$0 [-h] '帮助'"
    exit 1
}

if [[ $# -lt 1 ]]; then
    echo "参数个数不够, 请按照如下格式传入参数"
    usage
    exit 1
fi

while getopts ":oyh" opt
do
case $opt in
o)
    offline_install
    check_ansible
    exit
    ;;
y)
    oneline_install
    check_ansible
    exit
    ;;
h|*)
    usage
    exit
    ;;
esac
done