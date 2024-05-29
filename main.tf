# Create an RSA key of size 4096 bits
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# create my private key
resource "local_file" "key" {
  content  = tls_private_key.key.private_key_pem
  filename = "jenkins-key.pem"
  file_permission = 600
}
# create my public key on aws
resource "aws_key_pair" "key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.key.public_key_openssh
}
# create jenkins instance
resource "aws_instance" "jenkins" {
  ami                         = "ami-035cecbff25e0d91e" // redhat
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids      = [ aws_security_group.jenkins-sg.id ]
  associate_public_ip_address = true
  user_data                   = file("./userdata1.sh")

  tags = {
    Name = "jenkins-server"
  }
}
# create production instance
resource "aws_instance" "prod" {
  ami                         = "ami-035cecbff25e0d91e" // redhat
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids = [ aws_security_group.prod-sg.id ]
  associate_public_ip_address = true
  user_data                   = file("./userdata2.sh")

  tags = {
    Name = "prod-server"
  }
}

# creating jenkins security group
resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  description = "instance_security_group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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
  tags = {
    Name = "jenkins-sg"
  }
}
# create production security group
resource "aws_security_group" "prod-sg" {
  name        = "prod-sg"
  description = "instance_security_group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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
  tags = {
    Name = "prod-sg"
  }
}

output "jenkins-ip" {
  value = aws_instance.jenkins.public_ip
}

output "prod-ip" {
  value = aws_instance.prod.public_ip
}