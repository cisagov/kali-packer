terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "playground-terraform-state-storage"
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-1"
    key            = "ansible-role-dev-ssh-access/terraform.tfstate"
  }
}
