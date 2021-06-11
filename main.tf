provider "aws" {
	region  = "ap-south-1"
}

resource "aws_vpc" "base_vpc" {
	cidr_block = "10.0.0.0/16"
}

