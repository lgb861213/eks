#!/bin/bash

kubectl get deploy aws-load-balancer-controller -n kube-system

kubectl get deploy aws-load-balancer-controller -n kube-system -oyaml
