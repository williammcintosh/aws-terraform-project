dockerBuild: docker build -t rust-backend .
dockerRun: docker run -it --name rust-backend-instance -p 3000:3000 rust-backend
build: cargo build
run: cargo run
dockerTag: docker tag rust-backend:latest 676598651720.dkr.ecr.us-east-2.amazonaws.com/rust-backend:latest
dockerPush: docker push 676598651720.dkr.ecr.us-east-2.amazonaws.com/rust-backend:latest
dockerLogin: aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 676598651720.dkr.ecr.us-east-2.amazonaws.com

init:
  # Note this init uses the backend config shared portions
  terraform init -backend-config=../../../global/config/backend.hcl
apply: terraform apply
plan: terraform plan
destroy: terraform destroy -target aws_ecr_repository.app_ecr_repo
