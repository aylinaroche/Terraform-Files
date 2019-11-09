

resource "aws_iam_role" "WorkerRoleAylin" {
  name = "WorkerRoleAylin"

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

resource "aws_iam_policy" "eks-tagging" {
  name        = "production_resource_tagging_for_eks"
  path        = "/"
  description = "resource_tagging_for_eks"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "tag:UntagResources",
                "tag:GetTagValues",
                "tag:GetTagKeys",
                "tag:TagResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy-Aylin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.WorkerRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy-Aylin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.WorkerRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-Aylin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.WorkerRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = "${aws_iam_role.WorkerRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "worker-node-resource_tagging_for_eks" {
  policy_arn = "${aws_iam_policy.eks-tagging.arn}"
  role       = "${aws_iam_role.WorkerRoleAylin.name}"
}

resource "aws_iam_instance_profile" "WorkerRoleAylin-IAM" {
  name = "WorkerRoleAylin-IAM"
  role = "${aws_iam_role.WorkerRoleAylin.name}"
}

#SECURITY GROUP
resource "aws_security_group" "SGNodeAylin" {
  name        = "SGNodeAylin"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.VPCaylin}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                   = "worker-node-sg"
    "kubernetes.io/cluster/" = "ClusterAylin"
  }
}

resource "aws_security_group_rule" "worker-node-ingress-self-aylin" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.SGNodeAylin.id}"
  source_security_group_id = "${aws_security_group.SGNodeAylin.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "demo-node-ingress-cluster-aylin" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.SGNodeAylin.id}"
  source_security_group_id = "${aws_security_group.SGClusterAylin.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-node-https-aylin" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.SGClusterAylin.id}"
  source_security_group_id = "${aws_security_group.SGNodeAylin.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.SGClusterAylin.id}"
  to_port           = 443
  type              = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.ClusterAylin.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

locals {
  cluster-userdata = <<USERDATA
  #!/bin/bash
  set -o xtrace
  /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.ClusterAylin.endpoint}' --b64-cluster-ca '${aws_eks_cluster.ClusterAylin.certificate_authority.0.data}' 'SGClusterAylin'
  USERDATA
}

resource "aws_launch_configuration" "LC-ClusterAylin" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.WorkerRoleAylin-IAM.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t2.micro"
  name_prefix                 = "LC-ClusterAylin"
  security_groups             = ["${aws_security_group.SGNodeAylin.id}"]
  user_data_base64            = "${base64encode(local.cluster-userdata)}"
  key_name                    = "KeyPairAylin"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ASG-ClusterAylin" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.LC-ClusterAylin.id}"
  max_size             = 3
  min_size             = 2
  name                 = "ASG-ClusterAylin"
  vpc_zone_identifier  = "${var.SubnetsAylin}"

  tag {
    key                 = "Name"
    value               = "ASG-ClusterAylin"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/ClusterAylin"
    value               = "owned"
    propagate_at_launch = true
  }
}


resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${var.VPCaylin}"
  service_name      = "com.amazonaws.us-west-2.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.SGNodeAylin.id}",
  ]

  private_dns_enabled = true
}
