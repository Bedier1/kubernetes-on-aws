resource "aws_iam_role" "eks_cluster" {
  # The name of the role
  name = "eks-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "eks" {
  # Name of the cluster.
  name = "eks"
  role_arn = aws_iam_role.eks_cluster.arn
# version = by default latest
  version = 1.22
  vpc_config {
    # Indicates whether or not the Amazon EKS private API server endpoint is enabled
    endpoint_private_access = false
    # Indicates whether or not the Amazon EKS public API server endpoint is enabled
    endpoint_public_access = true

    # Must be in at least two different availability zones
    subnet_ids = [
      aws_subnet.public1.id,
      aws_subnet.public2.id,
      aws_subnet.private1.id,
      aws_subnet.private2.id
    ]
  }
  #extra
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy
  ]
}
