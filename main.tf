terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
      configuration_aliases = [aws, aws.dns]
    }

    archive = {
      source = "hashicorp/archive"
      version = ">= 2.3.0"
    } 
    
    external = {
      source = "hashicorp/external"
      version = ">= 2.2.3"
    } 
  }
}

data "aws_caller_identity" "current" {}