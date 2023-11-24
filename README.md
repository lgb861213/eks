利用eksctl结合yaml文件创建EKS集群

先决条件：

1、必需安装eksctl命令行工具

2、必需在~/.aws/credentials文件中设置IAM认证的token信息或者使用环境变量做设置

3、认证的IAM必须具有EC2、CloudFormation、EKS所有权限以及EC2 AutoScaling的列出和读取权限、并且IAM也必须具有列出读写和管理操作权限，而SystemManager必须有列出和读取权限

4、详见https://github.com/eksctl-io/eksctl/blob/main/README.md


参考资料：

1、https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/aws-load-balancer-controller.html 

