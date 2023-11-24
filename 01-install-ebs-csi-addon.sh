#!/bin/bash


#replace your eks cluster name
clusterName=aloda-test
#get oidc  endpoint
aws eks describe-cluster \
  --name $clusterName \      
  --query "cluster.identity.oidc.issuer" \
  --output text

#get oidc string
oidc_id=$(aws eks describe-cluster --name $clusterName --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
#check oidc enable or not, if return null that is not enable oidc
aws iam list-open-id-connect-providers | grep $oidc_id

#enable oidc for eks cluster
eksctl utils associate-iam-oidc-provider --cluster $clusterName --approve

