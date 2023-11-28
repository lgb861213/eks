#!/bin/bash
echo "请输入您要删除vpc公有子网tag关联的eks集群名称:"
read clusterName
if [[ -z $clusterName ]];then
    echo "您未输入集群名称"
    exit 0
fi
echo "正在获取eks集群的vpc id...."
VPC_ID=$(aws eks describe-cluster --name $clusterName --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo $VPC_ID
echo "正在获取vpc关联使用的igw"
IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPC_ID} --query "InternetGateways[].InternetGatewayId"  | jq -r '.[0]')
echo ${IGW_ID}
echo "正在获取公有子网信息..."
PUBLIC_SUBNETS=`aws ec2 describe-route-tables \
  --query  'RouteTables[*].Associations[].SubnetId' \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
    "Name=route.gateway-id,Values=${IGW_ID}" \
  | jq . -c`
#echo ${PUBLIC_SUBNETS}
#获取关联的私有子网信息
#参考https://stackoverflow.com/questions/48830793/aws-vpc-identify-private-and-public-subnet获取公有子网和私有子网信息
echo "正在获取私有子网信息..."
PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
  --filter Name=vpc-id,Values=${VPC_ID} \
  --query 'Subnets[].SubnetId' \
  | jq -c '[ .[] | select( . as $i | '${PUBLIC_SUBNETS}' | index($i) | not) ]')
#获取私有子网信息
#echo "获取到的私有子网信息...."
#echo $PRIVATE_SUBNETS

TAG_KEY="kubernetes.io/role/elb"
TAG_VALUE="1"
#为公有子网打上tag
# 删除字符串中的引号和方括号，并使用逗号分隔子网 ID
SUBNET_IDS_CLEAN=$(echo $PUBLIC_SUBNETS | sed 's/[][]//g' | sed 's/"//g' | sed 's/,/ /g')
#echo $SUBNET_IDS_CLEAN
# 循环遍历子网 ID 数组
for SUBNET_ID in $SUBNET_IDS_CLEAN; do
  # 在此处执行您的操作，例如打标签
  aws ec2 create-tags --resources $SUBNET_ID --tags Key=$TAG_KEY,Value=$TAG_VALUE;
  echo "已成功为子网 $SUBNET_ID 添加标签 $TAG_KEY = $TAG_VALUE" ;
done
