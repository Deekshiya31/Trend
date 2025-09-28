provider "aws" {
  region = "ap-south-1"
}

# ---------------------------
# IAM Role for Jenkins EC2
# ---------------------------
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required EKS policies
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins_role.name
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins UI"
  vpc_id      = data.aws_vpc.default.id  # using default VPC

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # you can restrict to your IP for safety
  }

  # Jenkins Web UI
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# Jenkins EC2 Instance
# ---------------------------
resource "aws_instance" "jenkins" {
  ami           = "ami-01b6d88af12965bb6"  # Amazon Linux 2023
  instance_type = "t3.micro"
  key_name      = "mumbai-key"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_instance_profile.name

  # Specify an Availability Zone for the instance
  availability_zone = data.aws_availability_zones.available.names[0]

  # Use default subnet
  subnet_id = data.aws_subnet.default.id

  tags = {
    Name = "jenkins-server"
  }

  # ---------------------------
  # User data: install Jenkins, Docker, Git, AWS CLI, kubectl
  # ---------------------------
  user_data = <<-EOF
    #!/bin/bash
    
    # Exit immediately if a command exits with a non-zero status.
    set -e

    echo "--- Starting user data script ---"

    # Update packages and install core dependencies
    echo "Updating system packages and installing core dependencies..."
    sudo dnf update -y
    sudo dnf install -y java-17-amazon-corretto git docker wget unzip dnf-utils

    # Configure and install Jenkins
    echo "Configuring and installing Jenkins..."
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf install -y jenkins

    # Start and enable Jenkins and Docker
    echo "Starting and enabling Jenkins and Docker services..."
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user

    # Install kubectl
    echo "Installing kubectl..."
    curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-07-18/bin/linux/amd64/kubectl
    chmod +x /usr/local/bin/kubectl

    # Install AWS CLI v2
    echo "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install

    # Clean up installation files
    rm awscliv2.zip
    rm -rf aws

    echo "--- User data script finished successfully ---"
  EOF
}

# ---------------------------
# Data sources for default VPC/Subnet
# ---------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id         = data.aws_vpc.default.id
  default_for_az = true
  availability_zone = data.aws_availability_zones.available.names[0]
}

