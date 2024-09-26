
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.24.2"
  cluster_name    = "message-app-eks-cluster"
  cluster_version = "1.30"

  cluster_addons = {
    aws-ebs-csi-driver = {}
  }
  subnet_ids = aws_subnet.private_subnets[*].id

  enable_irsa                    = true
  cluster_endpoint_public_access = true
  tags = {
    cluster = "message-app"
  }

  vpc_id = aws_vpc.message_vpc.id

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    instance_types         = ["t3a.medium"]
    vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
    iam_role_additional_policies = {
      "AmazonEBSCSIDriverPolicy" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  eks_managed_node_groups = {

    node_group = {
      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  access_entries = {
    # This example adds the current caller (you) as a cluster admin
    current_user = {
      principal_arn = data.aws_caller_identity.current.arn
      policy_associations = {
        policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}


data "aws_caller_identity" "current" {}
