Q1:部署安装ingress报Failed deploy model due to InvalidParameter: 1 validation error(s) found

Events:
  Type     Reason             Age                   From     Message
  ----     ------             ----                  ----     -------
  Warning  FailedDeployModel  7m50s (x63 over 12h)  ingress  Failed deploy model due to InvalidParameter: 1 validation error(s) found.
- minimum field value of 1, CreateTargetGroupInput.Port.

问题处理：
1. 核查ingress关联使用的svc的方式，确认为clusterIP，并且ingress安装关联使用的目标组的方式为instance
2. 根据https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/spec/
https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/
发现若ingress使用instance的方式进行部署，则svc需要使用NodePort的方式，解决办法是将目标组的方式由instance更改成ip方式
参考该链接： https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1695
# #####################################################################
Q2:如何查看aws loadbalancer controller的日志信息
问题处理：使用如下命令即可完成日志信息的查看
kubectl get pods -A |grep aws-load-balancer-controller|awk '{print $2}'|xargs -n1 kubectl logs -n kube-system
# 或者使用如下命令查看最近的50条日志记录信息
kubectl get pods -A |grep aws-load-balancer-controller|awk '{print $2}'|xargs -n1 kubectl logs --tail=50 -n kube-system
# #####################################################################
Q3:ingress删除目标失败，失败日志信息如下{"level":"error","ts":"2023-11-28T22:14:53Z","msg":"Reconciler error","controller":"ingress","object":{"name":"aws-ingress","namespace":"default"},"namespace":"default","name":"aws-ingress","reconcileID":"92a40f2d-5ff1-4f52-917e-bd990b991820","error":"failed to delete targetGroup: timed out waiting for the condition"}
问题处理：
查看cloudtrail的日志显示如下
Target group 'arn:aws:elasticloadbalancing:us-east-1:awsId:targetgroup/k8s-default-servicen-b7f80987ba/4f8374f642714aec' is currently in use by a listener or a rule
重新应用ingress，并获取ingress关联使用的svc，接着使用kubectl delete ingress ingres-name 删除关联的svc之后目标组成功被删除

参考https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/3037

Q4: 创建ingress报The Ingress "aws-ingress" is invalid: spec.rules[0].host: Invalid value: "*": a wildcard DNS-1123 subdomain must start with '*.', followed by a valid DNS subdomain, which must consist of lower case alphanumeric characters, '-' or '.' and end with an alphanumeric character (e.g. '*.example.com', regex used for validation is '\*\.[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')


