set fallback := true

init:
    # Note this init uses the backend config shared portions
    terraform init -backend-config=../../../global/config/backend.hcl
apply:
    terraform apply
plan:
    terraform plan
destroy:
    terraform destroy -target aws_secretsmanager_secret.db_credentials_copy_of_creds_bullshit_again_I_hate_this
refresh:
    terraform refresh