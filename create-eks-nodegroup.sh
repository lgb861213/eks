#!/bin/bash
# 请替换您的子网ID、AWS区域、EKS版本、EKS集群角色和集群安全组ID
EKS_SUBNET_ID1="subnet-0f1a3c5cbfd9708ab"
EKS_SUBNET_ID2="subnet-0c70b946820319511"
EKS_SUBNET_ID3="subnet-022a89c2dd2e976dd"
awsRegion="us-east-1"
EKSVersion="1.28"
EKS_CLUSTER_ROLE="arn:aws:iam::290796590818:role/eksClusterRole"
ClusterSecurityGroupId="sg-0b4c4e2eecf9e7b36"
EKS_CLUSTER_NAME="aloda-demo"
EKS_NODE_ROLE="arn:aws:iam::290796590818:role/EKSNodeInstanceRole"
NODE_INSTANCE_TYPE="t3.medium"
NODE_AMI_TYPE="AL2_x86_64"
NODE_DISK_SIZE=20
NODE_MIN_SIZE=2
NODE_MAX_SIZE=2
NODE_DESIRED_SIZE=2
CAPACITY_TYPE=SPOT #SPOT或者ON_DEMAND

create_managed_node_group() {
    echo "请输入要创建的托管节点组名称："
    read NODE_GROUP_NAME

    if [ -z "$NODE_GROUP_NAME" ]; then
        echo "请输入要创建的托管节点组名称才可以继续..."
        exit 1
    fi

    echo "正在创建托管节点组，请等待创建完成..."
    aws eks create-nodegroup --region "$awsRegion" --cluster-name "$EKS_CLUSTER_NAME" --nodegroup-name "$NODE_GROUP_NAME" \
    --node-role "$EKS_NODE_ROLE" --subnets "$EKS_SUBNET_ID1" "$EKS_SUBNET_ID2" "$EKS_SUBNET_ID3" \
    --capacity-type "$CAPACITY_TYPE"
    --instance-types "$NODE_INSTANCE_TYPE" --ami-type "$NODE_AMI_TYPE" --disk-size "$NODE_DISK_SIZE" \
    --scaling-config minSize="$NODE_MIN_SIZE",maxSize="$NODE_MAX_SIZE",desiredSize="$NODE_DESIRED_SIZE" >/dev/null 2>&1

    nodeGroupStatus=""
    while [ "$nodeGroupStatus" != "ACTIVE" ]; do
        nodeGroupStatus=$(aws eks describe-nodegroup --region "$awsRegion" --cluster-name "$EKS_CLUSTER_NAME" --nodegroup-name "$NODE_GROUP_NAME" --query 'nodegroup.status' --output text)
        #sleep 5
    done
    echo "托管节点组创建完成。"
}

# 创建托管节点组
create_managed_node_group