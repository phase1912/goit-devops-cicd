# During first run need to comment this file

terraform {
  backend "s3" {
    bucket         = "phase1912-lesson-db-module-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
