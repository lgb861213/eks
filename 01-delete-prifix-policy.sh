#!/bin/bash

#声明策略前缀
export prefix="AWSLoadBalancerControllerEKSPolicy"  # 替换为您的前缀
echo $prefix

# 获取以指定前缀开头的策略列表
policies=$(aws iam list-policies --query "Policies[?starts_with(PolicyName, '$prefix')].Arn" --output text )
echo $policies

# 检查策略列表是否为空
if [[ -z $policies ]]; then
  echo "没有找到以 $prefix 开头的策略"
  exit 0
fi

# 循环遍历并删除策略
for policyArn in $policies; do
  echo "正在删除策略: $policyArn"
  aws iam delete-policy --policy-arn "$policyArn"
done

echo "策略删除完成"

#aws iam list-policies --query 'Policies[?starts_with(PolicyName,`AWSLoadBalancerControllerEKSPolicy`)]'