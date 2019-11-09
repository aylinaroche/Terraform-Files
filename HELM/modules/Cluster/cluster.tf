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

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.EKSRoleAylin.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.EKSRoleAylin.name}"
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

resource "aws_eks_cluster" "ClusterAylin" {
  name     = "ClusterAylin"
  role_arn = "${aws_iam_role.EKSRoleAylin.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.SGClusterAylin.id}"]
    subnet_ids = "${var.SubnetsAylin}"
  }

  depends_on = [
    "aws_iam_role_policy_attachment.AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.AmazonEKSServicePolicy",
  ]
}
