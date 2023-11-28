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
PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
  --filter Name=vpc-id,Values=${VPC_ID} \
  --query 'Subnets[].SubnetId' \
  | jq -c '[ .[] | select( . as $i | '${PUBLIC_SUBNETS}' | index($i) | not) ]')
#获取私有子网信息
echo "获取到的私有子网信息...."
#echo $PRIVATE_SUBNETS

PUBLIC_SUBNETS_TAG_KEY="kubernetes.io/role/elb"
TAG_VALUE="1"
PRIVATE_SUBNETS_TAG_KEY="kubernetes.io/role/internal-elb"
#为公有子网打上tag
# 删除字符串中的引号和方括号，并使用逗号分隔子网 ID
PUBLIC_SUBNET_IDS_CLEAN=$(echo $PUBLIC_SUBNETS | sed 's/[][]//g' | sed 's/"//g' | sed 's/,/ /g')
PRIVATE_SUBNET_IDS_CLEAN=$(echo $PRIVATE_SUBNETS | sed 's/[][]//g' | sed 's/"//g' | sed 's/,/ /g')
#echo $SUBNET_IDS_CLEAN
# 循环遍历子网 ID 数组
# 函数：为子网添加标签
# 参数：
#   - $1: 子网 ID
#   - $2: 标签键
#   - $3: 标签值
function add_subnet_tag() {
  local SUBNET_ID="$1"
  local TAG_KEY="$2"
  local TAG_VALUE="$3"
  
  aws ec2 create-tags --resources $SUBNET_ID --tags Key=$TAG_KEY,Value=$TAG_VALUE
  echo "已为子网 $SUBNET_ID 添加标签 $TAG_KEY=$TAG_VALUE"
}

# 函数：从子网删除标签
# 参数：
#   - $1: 子网 ID
#   - $2: 标签键
#   - $3: 标签值
function remove_subnet_tag() {
  local SUBNET_ID="$1"
  local TAG_KEY="$2"
  local TAG_VALUE="$3"
  
  aws ec2 delete-tags --resources $SUBNET_ID --tags Key=$TAG_KEY,Value=$TAG_VALUE
  echo "已从子网 $SUBNET_ID 中删除标签 $TAG_KEY=$TAG_VALUE"
}
# 获取用户输入的操作
read -p "请输入要执行的操作（add/del）: " OPERATION

# 根据操作执行相应的函数
case $OPERATION in
  "add")
    for SUBNET_ID in $PUBLIC_SUBNET_IDS_CLEAN; do
      add_subnet_tag $SUBNET_ID $PUBLIC_SUBNETS_TAG_KEY $TAG_VALUE
    done
    for SUBNET_ID in $PRIVATE_SUBNET_IDS_CLEAN; do
      add_subnet_tag $SUBNET_ID $PRIVATE_SUBNETS_TAG_KEY $TAG_VALUE
    done
    ;;
  "del")
    for SUBNET_ID in $PUBLIC_SUBNET_IDS_CLEAN; do
      remove_subnet_tag $SUBNET_ID $PUBLIC_SUBNETS_TAG_KEY $TAG_VALUE
    done
    for SUBNET_ID in $PRIVATE_SUBNET_IDS_CLEAN; do
      remove_subnet_tag $SUBNET_ID $PRIVATE_SUBNETS_TAG_KEY $TAG_VALUE
    done
    ;;
  *)
    echo "无效的操作：$OPERATION"
    ;;
esac