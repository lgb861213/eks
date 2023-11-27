#!/bin/bash
#验证集群是否已安装好aws loadbalancer controller
lbControllerInstallFlag=$(kubectl get deployment -n kube-system aws-load-balancer-controller|grep -v NAME)
if [[ ! -z lbControllerInstallFlag ]];then
   echo "aws loadbalancer controller addon已安装好"
   exit 0
fi

#get aws account id
awsId=$(aws sts get-caller-identity --query "Account" --output text)
echo "请输入拟部署安装aws loadbalancer controller addon的eks集群名称:"
read clusterName
echo "请输入loadbalancer controller角色关联使用的策略名称,若直接回车将使用默认策略名称AWSLoadBalancerControllerEKSPolicy名称:"
read rolePolicyName
# 如果 Namespace 为空，则设置为 default
if [[ -z $rolePolicyName ]]; then
  rolePolicyName="AWSLoadBalancerControllerEKSPolicy"
fi
#echo "拟创建的策略名称为$rolePolicyName"

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json || echo "无法下载IAM策略文件"
counter=1
#检查策略是否存在
policyInfo=$(aws iam get-policy --policy-arn "arn:aws:iam::${awsId}:policy/$rolePolicyName"  2>&1)
policyExistsFlag=$(echo $policyInfo|grep   "not found")
# 检查策略是否存在
while [[ -z $policyExistsFlag ]]; do
  # 如果策略不存在，则追加数字并继续检查新的策略名称
  rolePolicyName="${rolePolicyName}${counter}"
  policyInfo=$(aws iam get-policy --policy-arn "arn:aws:iam::${awsId}:policy/$rolePolicyName"  2>&1)
  policyExistsFlag=$(echo $policyInfo|grep   "not found")
  counter=$((counter + 1))
done

echo "正在创建 $rolePolicyName 策略..."
pocliyArn=$(aws iam create-policy \
    --policy-name $rolePolicyName \
    --policy-document file://iam_policy.json  --query "Policy.Arn" --output text)
echo "请输入拟创建用于aws loadbalancer controller的角色名称:" 
read roleName
if [[ -z $roleName ]];then
    roleName="AmazonEKSLoadBalancerControllerRole"
fi 
echo "请输入拟用于load balancer controller的sa:"
read $sa 
if [[ -z $sa ]];then
    sa="aws-load-balancer-controller"
fi
#判断sa是否已存在
saExistFlag=$(kubectl get sa -n kube-system|grep $sa )
if [[ -z saExistFlag ]];then 
   sa=${sa}${counter}
fi
echo "正在为load balancer controller创建sa并且关联 $roleName 角色 ......"

eksctl create iamserviceaccount --cluster $clusterName --namespace=kube-system --name=$sa --role-name  $roleName --attach-policy-arn $pocliyArn --override-existing-serviceaccounts --approve

echo "开始准备利用helm部署安装loadbalancer controller addon...."
echo "正在添加eks-charts存储库..."
helm repo add eks https://aws.github.io/eks-charts
echo "正在更新本地存储库...."
helm repo update eks
echo "开始安装aws loadbalancer controller...."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clusterName --set serviceAccount.create=false --set serviceAccount.name=$sa 
echo "aws loadbalancer controller addon已安装完成，正在验证控制器是否正常部署..."
kubectl get deployment -n kube-system aws-load-balancer-controller


#卸载aws-load-balancer-controller
#helm uninstall aws-load-balancer-controller -n kube-system



