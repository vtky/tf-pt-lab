variable "tag" {
  default = "example"
}

variable "profile" {
  default = "default"
}

variable "shared_credentials_file" {
    default = "PATH TO SHARED CREDS FILE"
}

# AWS Regions
#us-east-2       # US East (Ohio)
#us-east-1       # US East (N. Virginia)
#us-west-1       # US West (N. California)
#us-west-2       # US West (Oregon)
#ap-east-1       # Asia Pacific (Hong Kong)
#ap-south-1      # Asia Pacific (Mumbai)
#ap-northeast-3  # Asia Pacific (Osaka-Local)
#ap-northeast-2  # Asia Pacific (Seoul)
#ap-southeast-1  # Asia Pacific (Singapore)
#ap-southeast-2  # Asia Pacific (Sydney)
#ap-northeast-1  # Asia Pacific (Tokyo)
#ca-central-1    # Canada (Central)
#cn-north-1      # China (Beijing)
#cn-northwest-1  # China (Ningxia)
#eu-central-1    # Europe (Frankfurt)
#eu-west-1       # Europe (Ireland)
#eu-west-2       # Europe (London)
#eu-west-3       # Europe (Paris)
#eu-north-1      # Europe (Stockholm)
#me-south-1      # Middle East (Bahrain)
#sa-east-1       # South America (Sao Paulo)
variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_az" {
  default = "ap-southeast-1a"
}

variable "instance_type" {
  default = "t3a.large"
}

variable "client_instance_count" {
  default = "1"
}

variable "server_instance_count" {
  default = "1"
}

# aws --profile suss ec2 describe-vpcs | jq ".Vpcs[].CidrBlock" | sort
variable "aws_vpc_cidr_block" {
  default = "10.10.0.0/16"
}

# aws --profile suss ec2 describe-subnets | jq ".Subnets[].CidrBlock" | sort
variable "aws_vpc_subnet_cidr_block" {
  default = "10.10.1.0/24"
}

variable "zoneid" {
  default = "example.com."
}