terraform {
  backend "s3" {
    bucket         = "terraform-state-backend-eks-20246767676"  # CHANGE THIS to unique name
    key            = "production/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}