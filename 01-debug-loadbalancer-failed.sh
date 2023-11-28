#!/bin/bash
#查看loadbalancer的svc详细信息
kubectl get svc
kubectl describe svc nginx-lb
#异常信息Failed build model due to unable to resolve at least one subnet (0 match VPC and tags) 
#公有子网需要打上tag Key为kubernetes.io/role/elb,值为1的tag
#私有子网需要打上tag Key为kubernetes.io/role/internal-elb,值为1的tag