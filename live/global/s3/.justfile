set fallback := true

init:
    # Note this init uses the backend config shared portions
    terraform init -backend-config=../config/backend.hcl
apply:
    terraform apply
plan:
    terraform plan
destroy:
    terraform destroy -target aws_s3_bucket.terraform_state
refresh:
    terraform refresh