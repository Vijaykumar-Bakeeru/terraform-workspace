terraform {
  backend "s3" {
    bucket = "vijay2026.flm"
    #key          = "dev/terraform.tfstate"
    region               = "ap-south-1"
    encrypt              = true
    use_lockfile         = true
    workspace_key_prefix = "env"
  }
}





