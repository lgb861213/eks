#aws loadbalancer controller 注解
#https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/service/annotations/
kubectl annotate sa aws-load-balancer-controller eks.amazonaws.com/role-arn="arn:aws:iam::replace_your_aws_id:role/replace_your_role_name"  -n kube-system --overwrite