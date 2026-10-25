terraform {
  backend "s3" {
    bucket       = "vijay2026.flm"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
