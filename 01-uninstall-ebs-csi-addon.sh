#!/bin/bash

clusterName="aloda-test"
addonName="aws-ebs-csi-driver"

if aws eks describe-addon --cluster-name "$clusterName" --addon-name "$addonName" &> /dev/null; then
    echo "AWS EBS CSI Driver 插件已安装，开始卸载..."
    aws eks delete-addon --cluster-name "$clusterName" --addon-name "$addonName"
else
    echo "AWS EBS CSI Driver 插件未安装，无需卸载."
fi