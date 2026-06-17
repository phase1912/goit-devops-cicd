# During first run need to comment this file

terraform {
  backend "s3" {
    bucket         = "phase1912-lesson-5-terraform-state"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
