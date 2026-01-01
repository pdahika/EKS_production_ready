# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# SSH Key Pair for EC2 instances
resource "aws_key_pair" "eks_nodes" {
  key_name   = "${var.cluster_name}-key-${random_id.suffix.hex}"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-key"
  })
}

# Bastion Host (Optional)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.eks_optimized.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = aws_key_pair.eks_nodes.key_name

  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-bastion"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ssh_ips
    content {
      description = "SSH from ${ingress.value}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-bastion-sg"
  })
}