
# Create IAM role for EKS Node Group
resource "aws_iam_role" "nodes_general" {
  # The name of the role
  name = "eks-node-group-general"
  # The policy that grants an entity permission to assume the role.
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }, 
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy_general" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.nodes_general.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy_general" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.nodes_general.name
}
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.nodes_general.name
}

/* 
  this for if you want enable  storage with ebs <<csi driver >>

resource "aws_iam_role_policy_attachment" "eks-ebs" {
    role =   aws_iam_role.nodes_general.name
    policy_arn = "arn:aws:iam::611469625560:policy/eks-ebs"

}
*/ 

#this is for autoscaler
/*

resource "aws_iam_role_policy_attachment" "eks-autoscaler" {
    role =   aws_iam_role.nodes_general.name
    policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}

*/



resource "aws_eks_node_group" "nodes_general" {
  # Name of the EKS Cluster.
  cluster_name = aws_eks_cluster.eks.name

  # Name of the EKS Node Group.
  node_group_name = "nodes-general"

  # Amazon Resource Name (ARN) of the IAM Role that provides permissions for the EKS Node Group.
  node_role_arn = aws_iam_role.nodes_general.arn

  # Identifiers of EC2 Subnets to associate with the EKS Node Group. 
  # These subnets must have the following resource tag: kubernetes.io/cluster/CLUSTER_NAME 
  # (where CLUSTER_NAME is replaced with the name of the EKS Cluster).
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  scaling_config {
    desired_size = 4
    max_size = 5
    min_size = 2
  }
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  force_update_version = false
  instance_types = ["t2.micro"]

  labels = {
    role = "nodes-general"
  }

  # Kubernetes version
  #be default the latest

  version = 1.22

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy_general,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy_general,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    
  ]
    tags = {
    Name = "Private-Node-Group"
    # Cluster Autoscaler Tags /this is must 

    "k8s.io/cluster-autoscaler/eks" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"	    
  }
}

