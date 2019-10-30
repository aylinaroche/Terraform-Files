resource "aws_iam_role" "EKSRoleAylin" {
  name = "EKSRoleAylin"

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

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy-Aylin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.EKSRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy-Aylin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.EKSRoleAylin.name}"
}

resource "aws_eks_cluster" "ClusterAylin" {
  name     = "ClusterAylin"
  role_arn = "${aws_iam_role.EKSRoleAylin.arn}"

  vpc_config {
    subnet_ids = "${var.SubnetsAylin}"
  }
}

resource "aws_security_group" "SGClusterAylin" {
  name        = "SGClusterAylin"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.VPCaylin}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SGClusterAylin"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
/*resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = ["A.B.C.D/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.demo-cluster.id}"
  to_port           = 443
  type              = "ingress"
}
*/

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

resource "aws_iam_instance_profile" "WorkerRoleAylin-IAM" {
  name = "WorkerRoleAylin-IAM"
  role = "${aws_iam_role.WorkerRoleAylin.name}"
}

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
    Name = "SGNodeAylin"
  }
  /*
  tags = "${
    map(
     "Name", "SG-Aylin",
     "kubernetes.io/cluster/${aws_eks_cluster.ClusterAylin}", "owned",
    )
  }"*/
}

resource "aws_security_group_rule" "aws_security_group_rule-aylin" {
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
  key_name = "KeyPairAylin"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ASG-ClusterAylin" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.LC-ClusterAylin.id}"
  max_size             = 1
  min_size             = 1
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

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: aws-auth
    namespace: kube-system
  data:
    mapRoles: |
      - rolearn: ${aws_iam_role.WorkerRoleAylin.arn}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
CONFIGMAPAWSAUTH
}

