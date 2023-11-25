#!/bin/bash
echo "check cluster run ebs csi driver pods or not..."
kubectl get all -l app.kubernetes.io/name=aws-ebs-csi-driver -n kube-system
echo "正在排查ebs挂载到pod失败原因..."
echo "请输入要查询到pvc name:"
read PVC_NAME
echo "请输入拟查询到pvc所在到namespace名称:"
read NAMESPACE
# 如果 Namespace 为空，则设置为 default
if [[ -z $NAMESPACE ]]; then
  NAMESPACE="default"
fi
echo "正在输出位于 $NAMESPACE 的 $PVC_NAME 的详细信息....."
kubectl describe pvc $PVC_NAME -n $NAMESPACE

echo "determine if the ebs-csi-controller pods' service account has the correct annotation..."
kubectl describe sa ebs-csi-controller-sa -n kube-system

echo "Review the Amazon EBS CSI controller pods' logs....."
printf "正在打印ebs-plugin容器日志信息....\n"
echo "show ebs-plugin container logs...."
kubectl logs deployment/ebs-csi-controller -n kube-system -c ebs-plugin
kubectl logs daemonset/ebs-csi-node -n kube-system -c ebs-plugin
printf "正在打印csi-provisioner容器日志信息....\n"
echo "show csi-provisioner container logs..."
kubectl logs deployment/ebs-csi-controller -n kube-system -c csi-provisioner
printf "正在打印csi-attacher容器日志信息....\n"
echo "show csi-attacher container logs..."
kubectl logs deployment/ebs-csi-controller -n kube-system -c csi-attacher