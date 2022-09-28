eksctl utils associate-iam-oidc-provider \
    --region eu-central-1 \
    --cluster eks \
    --approve

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::611469625560:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve


#installing aws load balancer 
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=eu-central-1 \
  --set vpcId="enter your vpc id "  \
  #enter which repo your helm
  # check it https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

  --set image.repository=602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller


#external dns
#external dns arn arn:aws:iam::611469625560:policy/external-dns
#name: external-dns
#create iamserviceaccount
eksctl create iamserviceaccount \
    --name external-dns \
    --namespace default \
    --cluster eks \

    --attach-policy-arn arn:aws:iam::611469625560:policy/external-dns \
    --approve \
    --override-existing-serviceaccounts
#auto mount target group to load balancer
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

#after editing cluster-autoscaler-autodiscover.yaml

kubectl apply -f  cluster-autoscaler-autodiscover.yaml
#iam service account for autoscaler
eksctl create iamserviceaccount \
  --cluster=eks \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::aws:policy/AutoScalingFullAccess \
  --override-existing-serviceaccounts \
  --approve
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
