terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}


resource "aws_vpc" "ddc_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "ddc-vpc"
  }
}

resource "aws_internet_gateway" "ddc_igw" {
  vpc_id = aws_vpc.ddc_vpc.id
  tags = {
    "Name" = "ddc-igw"
  }
}

resource "aws_subnet" "ddc_subn_a" {
  cidr_block = "10.0.0.0/24"
  vpc_id     = aws_vpc.ddc_vpc.id
  # availability_zone = us-west-1a
  tags = {
    "Name" = "ddc-subn-a"
  }
}

resource "aws_subnet" "ddc_subn_b" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.ddc_vpc.id
  # availability_zone = us-west-1b

  tags = {
    "Name" = "ddc-subn-b"
  }
}

resource "aws_security_group" "ddc_sg_public" {
  name        = "ddc-sg-public"
  description = "Allow inbound traffic via HTTP"
  vpc_id      = aws_vpc.ddc_vpc.id

  ingress {
    description = "Allow TLS Connections"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP Connections"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH Connections"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 8765 Connections"
    from_port   = 8765
    to_port     = 8765
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
    "Name" = "ddc-sg-public"
  }
}



resource "aws_security_group" "ddc_sg_private" {
  name        = "ddc-sg-private"
  description = "Allow data lake to receive connections"
  vpc_id      = aws_vpc.ddc_vpc.id
  ingress {
    description = "Allow TLS Connections"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24"]
  }

  tags = {
    "Name" = "ddc-sg-private"
  }
}

resource "aws_route_table" "ddc_rt" {
  vpc_id = aws_vpc.ddc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ddc_igw.id
  }

  tags = {
    "Name" = "ddc-rt"
  }
}

resource "aws_route_table_association" "ddc_rta" {
  subnet_id      = aws_subnet.ddc_subn_a.id
  route_table_id = aws_route_table.ddc_rt.id
}




# data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ddc_ec2_flask" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.ddc_subn_a.id
  key_name                    = "ddc"
  security_groups             = [aws_security_group.ddc_sg_public.id]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/ddc.pem")
      host        = aws_instance.ddc_ec2_flask.public_ip
    }

    inline = [
      "echo 'Wait until SSH is ready'",
      "mkdir .aws",
      "touch .aws/credentials",
      "echo [default] >> .aws/credentials",
      "echo aws_access_key_id = ${var.aws_access_key_id} >> .aws/credentials",
      "echo aws_secret_access_key = ${var.aws_secret_access_key} >> .aws/credentials",
      "git clone ${var.git_server}",
      "bash ~/Setup-Flask-Machine/setup.sh",
      # "sudo add-apt-repository universe",
      # "sudo apt-get -y update",
      # "sudo apt -y install python3-pip",
      # "cd Setup-Flask-Machine/python_flask",
      # "pip3 install -r requirements.txt",
      # "pip3 install connexion[swagger-ui]",
      # "nohup python3 -m tracking_server &"
    ]
  }

  tags = {
    "Name" = "ddc-ec2-flask"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ddc_ec2_flask.id
  allocation_id = "eipalloc-ff14f5cb"
}


resource "aws_s3_bucket" "ddc_s3_bucket" {
  bucket = "ddc-s3-bucket"
  acl    = "private"
  tags = {
    "Name" = "ddc-s3-bucket"
  }
}

resource "aws_s3_access_point" "ddc_s3_ap" {
  bucket = aws_s3_bucket.ddc_s3_bucket.id
  name   = "ddc-s3-ap"

  # VPC must be specified for S3 on Outposts
  vpc_configuration {
    vpc_id = aws_vpc.ddc_vpc.id
  }
}


# resource "aws_s3_bucket" "ddc_s3_bucket" {
#   bucket = "ddc-s3-bucket"
#   acl    = "private"
#   tags = {
#     "Name" = "ddc-s3-bucket"
#   }
# }

# resource "aws_iam_role" "ddc_firehose_role" {
#   name = "firehose_role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "firehose.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
#   tags = {
#     "Name" = "ddc-firehose-role"
#   }
# }

# resource "aws_kinesis_firehose_delivery_stream" "ddc_firehose_stream" {
#   name        = "ddc-firehose"
#   destination = "s3"

#   s3_configuration {
#     role_arn   = aws_iam_role.ddc_firehose_role.arn
#     bucket_arn = aws_s3_bucket.ddc_s3_bucket.arn
#   }
#   tags = {
#     "Name" = "ddc-firehose-strean"
#   }
# }
