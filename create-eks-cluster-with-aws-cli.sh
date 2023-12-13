#!/bin/bash

check_aws_cli(){
    # 检查aws命令是否存在
    if ! command -v aws &> /dev/null;then
        echo " aws cli未安装，请先安装aws cli工具"
        exit 1
    fi
    # 检查AWS CLI凭证是否配置
    CertInfo=$(aws configure list|grep -v grep|grep _key|grep not)
    if [ ! -z "${CertInfo}" ];then
        echo "AWS CLI 访问密钥未配置，请先运行 'aws configure' 命令配置凭证。"
        exit 1
    fi

}

create_eks_cluster() {
    # 请替换您的子网ID、AWS区域、EKS版本、EKS集群角色和集群安全组ID
    EKS_SUBNET_ID1="subnet-0f1a3c5cbfd9708ab"
    EKS_SUBNET_ID2="subnet-0c70b946820319511"
    EKS_SUBNET_ID3="subnet-022a89c2dd2e976dd"
    awsRegion="us-east-1"
    EKSVersion="1.28"
    EKS_CLUSTER_ROLE="arn:aws:iam::290796590818:role/eksClusterRole"
    ClusterSecurityGroupId="sg-0b4c4e2eecf9e7b36"

    echo "请输入要创建的EKS集群名称："
    read EKS_CLUSTER_NAME

    if [ -z "$EKS_CLUSTER_NAME" ]; then
        echo "请输入要创建的集群名称才可以继续..."
        exit 1
    fi

    echo "正在创建EKS集群，请等待创建完成..."
    aws eks create-cluster --region "$awsRegion" --name "$EKS_CLUSTER_NAME" --kubernetes-version "$EKSVersion" \
    --role-arn "$EKS_CLUSTER_ROLE" \
    --resources-vpc-config subnetIds="$EKS_SUBNET_ID1","$EKS_SUBNET_ID2","$EKS_SUBNET_ID3",\
    securityGroupIds="$ClusterSecurityGroupId",endpointPublicAccess=true,endpointPrivateAccess=true >/dev/null 2>&1
    clusterStatus=""
    while [ "$clusterStatus" != "ACTIVE" ]; do
        clusterStatus=$(aws eks describe-cluster --region "$awsRegion" --name "$EKS_CLUSTER_NAME" --query 'cluster.status' --output text)
        #sleep 5
    done
    echo "EKS集群创建完成。"
    echo "正在创建kubectl config文件..."
    aws eks update-kubeconfig --region $awsRegion --name "$EKS_CLUSTER_NAME"
}



# 检查AWS CLI是否安装
check_aws_cli

# 创建EKS集群
create_eks_cluster

