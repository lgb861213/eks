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

