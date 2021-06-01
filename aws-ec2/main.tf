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
  region  = "us-east-2"
}

#Create S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "aws.bi"
  acl    = "private"

  tags = {
    Name        = "my-bucket"
    Environment = "Dev"
  }
}

#Creating IAMrole for ec2.

resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "s3-role"
  #assume_role_policy = "${file("assumerolepolicy.json")}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
   })
}

#Creating Iam policy
resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
#   policy      = "${file("policys3bucket.json")}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
})
}

#Attatching policy to role
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.ec2_s3_access_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

#Creating Iam instance profile
resource "aws_iam_instance_profile" "test_profile" {
  name  = "test_profile"
  role = "${aws_iam_role.ec2_s3_access_role.name}"
}

#Create ec2 Instance which accesses s3 bucket using Iam role
resource "aws_instance" "app_server" {
  ami           = "ami-03b6c8bd55e00d5ed"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"

  tags = {
    Name = "InstanceFromTerraform"
  }
}


