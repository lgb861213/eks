#!/bin/bash
#查看loadbalancer的svc详细信息
kubectl get svc
kubectl describe svc nginx-lb
#异常信息Failed build model due to unable to resolve at least one subnet (0 match VPC and tags) 