terraform {

  required_version = ">= 1.3.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }

  backend "s3" {
    bucket = "stormit-tf-backend"
    key    = "terraform/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "stormit-tf-statelock"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}