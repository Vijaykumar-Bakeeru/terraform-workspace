Option 1: Separate state files using Terraform workspaces
This is the simplest option if you want to keep your existing files and use terraform workspace select dev or prod.

With an S3 backend, configure backend.tf like this:
backend.tf
terraform {
backend "s3" {
bucket = "your-terraform-state-bucket"
key = "solv-india/terraform.tfstate"
region = "ap-south-2"
encrypt = true
use_lockfile = true
workspace_key_prefix = "env"
}
}

Replace the bucket name with your actual S3 bucket. Enable versioning on that bucket as well.

With this configuration, Terraform stores state separately for each workspace:
Workspace S3 state key
default solv-india/terraform.tfstate
dev env/dev/solv-india/terraform.tfstate
prod env/prod/solv-india/terraform.tfstate

Terraform creates and manages the separate workspace state objects. You do not need to create the state files manually.
Deploy using your existing .tfvars files

1. Terraform workspace commands
   Command Purpose

terraform init -reconfigure
terraform workspace list List all workspaces
terraform workspace show Show the current workspace
terraform workspace new dev Create a workspace
terraform workspace select dev Switch to a workspace
terraform workspace select -or-create dev Select a workspace or create it if missing
terraform workspace delete dev Delete a workspace
terraform workspace delete -force dev Delete a workspace even if it has tracked resources; use with caution

Create the workspaces once:
terraform init

terraform workspace new dev
terraform workspace new prod

Deploy Dev:
terraform workspace select dev

terraform plan -var-file="dev.tfvars" -out="dev.tfplan"
terraform apply dev.tfplan

Deploy Prod:
terraform workspace select prod

terraform plan -var-file="prod.tfvars" -out="prod.tfplan"
terraform apply prod.tfplan

Your main.tf and modules remain shared. The .tfvars file supplies the environment-specific values, while the workspace determines which state Terraform uses.

Important: If your configuration needs different AWS accounts or IAM roles for Dev and Prod, configure those credentials or provider role assumptions separately. Workspace selection alone does not switch AWS accounts.
Option 2: Separate state files without workspaces
If you want explicit control over each environment's state, use separate backend configuration files.

Keep your existing structure and add:
terraform-project/
├── modules/
├── backend.tf
├── backend-dev.hcl
├── backend-prod.hcl
├── dev.tfvars
├── prod.tfvars
├── main.tf
└── variable.tf

Use a shared backend.tf with an empty S3 backend declaration:
terraform {
backend "s3" {}
}

backend-dev.hcl:
bucket = "your-terraform-state-bucket"
key = "solv-india/dev/terraform.tfstate"
region = "ap-south-2"
encrypt = true
use_lockfile = true

backend-prod.hcl:
bucket = "your-terraform-state-bucket"
key = "solv-india/prod/terraform.tfstate"
region = "ap-south-2"
encrypt = true
use_lockfile = true

Initialize and deploy each environment with its corresponding backend:

# Dev

terraform init -reconfigure -backend-config=backend-dev.hcl
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Prod

terraform init -reconfigure -backend-config=backend-prod.hcl
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

Here, -reconfigure switches the current working directory to the specified backend configuration. Do not use this method to switch environments casually if you have local state or uncommitted infrastructure changes; verify the state and backend before proceeding.
Which should you choose?

- Use workspaces if you want a simple workflow with dev.tfvars, prod.tfvars, and one shared backend configuration.
- Use separate backend files if you want each environment's state key to be explicitly configured and reviewed.
  One final best practice: add .terraform/, _.tfstate, _.tfstate._, and _.tfplan to .gitignore. Keep Terraform state in S3, not in Git, because state can contain sensitive information.

For your current repository, I'd start with S3 backend + workspaces, provided both environments can safely share the same AWS credentials and access boundary.

terraform init -reconfigure \
 -backend-config=backend-dev.hcl

terraform plan -destroy -var-file="dev.tfvars"
terraform destroy -var-file="dev.tfvars"

terraform init -reconfigure \
 -backend-config=backend-prod.hcl

terraform plan -destroy -var-file="prod.tfvars"
terraform destroy -var-file="prod.tfvars"
