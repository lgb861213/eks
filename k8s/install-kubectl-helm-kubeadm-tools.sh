#!/bin/bash

# 检查当前操作系统是否为Linux x86_64
check_os() {
    if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
        echo "仅支持 Linux x86_64 操作系统。当前操作系统不符合要求，无法继续安装。"
        exit 1
    fi
}

install_kubectl() {
    echo "请输入拟部署安装的kubectl版本，若直接回车将安装最新版本:"
    read KUBECTL_VERSION
    if [ -z "$KUBECTL_VERSION" ]; then
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    fi
    echo "正在安装$KUBECTL_VERSION版本的kubectl..."
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
}

install_kubeadm() {
    echo "请输入拟部署安装的kubeadm版本，若直接回车将安装最新版本:"
    read KUBEADM_VERSION
    if [ -z "$KUBEADM_VERSION" ]; then
        KUBEADM_VERSION=$(curl -L -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    fi
    echo "正在安装$KUBEADM_VERSION版本的kubeadm..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/v${KUBEADM_VERSION}/bin/linux/amd64/kubeadm"
    sudo chmod +x kubeadm
    sudo mv kubeadm /usr/local/bin/
}

install_helm() {
    echo "请输入拟部署安装的helm版本，若直接回车将安装最新版本:"
    read HELM_VERSION
    if [ -z "$HELM_VERSION" ]; then
        echo "正在安装最新版本的helm软件"
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        sudo chmod 700 get_helm.sh
        sudo bash get_helm.sh
    else
        echo "正在安装$HELM_VERSION版本的helm..."
        curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
        sudo tar zxvf "helm-${HELM_VERSION}-linux-amd64.tar.gz"
        cd "helm-${HELM_VERSION}"
        sudo mv linux-amd64/helm /usr/local/bin/helm
    fi
}

# 主函数
main() {
    check_os
    install_kubectl
    install_kubeadm
    install_helm
}

main