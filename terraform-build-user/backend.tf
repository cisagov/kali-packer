terraform {
  backend "s3" {
    bucket         = "cisa-cool-terraform-state"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    key            = "kali-packer/terraform-build-user.tfstate"
    profile        = "cool-terraform-backend"
    region         = "us-east-1"
  }
}
