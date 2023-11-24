#!/bin/sh


#replace your eks cluster name
clusterName=aloda-test
#get oidc  endpoint
printf "正在获取eks 集群的oidc endpoint地址\n"

aws eks describe-cluster --name $clusterName --query "cluster.identity.oidc.issuer" --output text

#get oidc string
printf "正在获取eks 集群的oidc字符串\n"
oidc_id=$(aws eks describe-cluster --name $clusterName --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
#check oidc enable or not, if return null that is not enable oidc
printf "正在确认eks集群是否启用oidc \n"
aws iam list-open-id-connect-providers | grep $oidc_id
#enable oidc for eks cluster
printf "正在为eks集群启用oidc \n"
eksctl utils associate-iam-oidc-provider --cluster $clusterName --approve

# create aws ebs csi driver trust policy for eks
printf "正在创建IAM信任实体策略\n"
role_trust_file=aws-ebs-csi-driver-trust-policy-eks.json
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::195495575045:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/A357D6680CACC3FE811997EAE0BEDDCD"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/A357D6680CACC3FE811997EAE0BEDDCD:aud": "sts.amazonaws.com",
          "oidc.eks.us-east-1.amazonaws.com/id/A357D6680CACC3FE811997EAE0BEDDCD:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}' | sed "s/A357D6680CACC3FE811997EAE0BEDDCD/$oidc_id/g" | tee $role_trust_file

#set IAM Role Name to want to create.
export ebs_csi_role_name=AmazonEKS_EBS_CSI_DriverRole-eks
printf "正在创建$ebs_csi_role_name 并将创建好的角色的arn地址存入role_arn变量中\n"
# Use the above trusted entity policy file to create an IAM role and store the arn of the created role in a variable.
# export role_arn=$(aws iam create-role \
#   --role-name  $ebs_csi_role_name\
#   --assume-role-policy-document file://"$role_trust_file" --query "Role.Arn" --output text)
# 检查角色是否已存在
existing_role_arn=$(aws iam get-role --role-name "$ebs_csi_role_name" --query "Role.Arn" --output text)
# 如果角色不存在，则创建角色
if [ -z "$existing_role_arn" ]; then
    role_arn=$(aws iam create-role \
        --role-name "$ebs_csi_role_name" \
        --assume-role-policy-document file://"$role_trust_file" \
        --query "Role.Arn" --output text)
else
    echo "角色已存在，无需创建。"
    role_arn=$existing_role_arn
fi


#Associate the necessary permission policies with the created role
printf "正在为创建好的IAM角色关联名称为AmazonEBSCSIDriverPolicy的serve-role策略...\n"
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --role-name $ebs_csi_role_name

#Deploying and installing aws ebs csi add-on
printf "正在部署安装aws ebs csi driver...\n"
export addonName="aws-ebs-csi-driver"
# aws eks create-addon  --cluster-name $clusterName --addon-name aws-ebs-csi-driver --service-account-role-arn $role_arn
printf "正在校验角色的arn地址:$role_arn \n"
if ! aws eks describe-addon --cluster-name "$clusterName" --addon-name "$addonName" &> /dev/null; then
    echo "AWS EBS CSI Driver 插件未安装，开始安装..."
    aws eks create-addon --cluster-name "$clusterName" --addon-name "$addonName" --service-account-role-arn "$role_arn"
else
    echo "AWS EBS CSI Driver 插件已存在，开始更新..."
    aws eks update-addon --cluster-name "$clusterName" --addon-name "$addonName" --service-account-role-arn "$role_arn"
fi
