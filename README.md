# Terraform Rust AWS Site

# Inspiration

I was inspired to better understand AWS environments related to postgres databases and hosting a rust website. This project began with the recently published book by Yevgeniy Brikman titled "Terraform Up & Running", and then transitioned into a rust website connected to a postgres RDS.

---

# AWS Pipeline Workflow for Terraform and Rust Environment                                                        
                                                                                                                      
### High-Level AWS CodePipeline Description                                                                        
                                                                                                                      
![High-Level AWS CodePipeline Diagram](https://d2908q01vomqb2.cloudfront.net/22d200f8670dbdb3e253a90eee5098477c95c23d/2019/11/19/DevSecOps-Figure1.png)                       

### Components of the Pipeline:

1. **Source Stage**: Code repository (like GitHub, Bitbucket, AWS CodeCommit) triggers the pipeline when changes are pushed.
2. **Build Stage**: AWS CodeBuild compiles the Rust code, runs tests, and packages the application.
3. **Artifact Storage**: AWS S3 bucket stores the built artifacts securely.
4. **Deployment Stage**: AWS CodeDeploy automates the deployment of the application to AWS ECS using (serverless compute for containers.)
5. **AWS ECS with Fargate**: Runs containerized Rust applications with easy scaling and management.
6. **Load Balancing**: AWS ALB (Application Load Balancer) distributes incoming application traffic across
  multiple targets.                                                                                                   

### Supporting AWS Services:

- **Amazon RDS (PostgreSQL)**: Managed relational database service hosting the application database.
- **Amazon ECR (Elastic Container Registry)**: Docker container registry stores the Rust application container images.
- **AWS Secrets Manager**: Manages database credentials and other secrets, providing secure access to ECS tasks.
- **AWS IAM**: Defines roles and policies for secure access to AWS resources.
- **AWS VPC**: Provides a private section of the AWS cloud where AWS resources can be launched in a defined virtual network.
- **Amazon DynamoDB**: Provides a managed NoSQL database for lock tables to support state locking in Terraform.
- **Remote State Backend (S3)**: S3 buckets store the state files for Terraform, ensuring consistent configurations and change tracking.

### Continuous Deployment Flow:

1. Developer pushes code to the Source Repository.                                                                
2. AWS CodePipeline is triggered.                                                                                 
3. Code is built and tested using AWS CodeBuild.                                                                  
4. Build artifacts are stored in an AWS S3 bucket.                                                                
5. AWS CodeDeploy orchestrates deployment to AWS ECS with Fargate tasks.                                          
6. The ALB directs traffic to new tasks once they are healthy and running.                                        
7. Monitoring and logging tools (like AWS CloudWatch) provide insights and alerting for application performance and health.   

---

# Installing and Starting Web Application

### 1. Create IAM Root Account

You will use this account only for navigating through the AWS console.

1. Go to https://aws.amazon.com/
2. Enter your credit card information as prompted.
3. Go for the basic plan.

### 2. Create User Account

Next, we create a more limited user account that we’re using to log in within our terraform code.

1. Go here https://us-east-2.console.aws.amazon.com/iamv2/home
2. Create a user under your name, give them the access key group “Application Running On an AWS Compute Service” and click “Save”

I recommend saving these variables someplace on your local machine. Use your favorite password storage software like keychain.

### 3. Install Terraform

1. Install “terraform” https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli?in=terraform%2Faws-get-started

### 4. Export Env Variables

1. Open VSCode (or the editor of your choice).
2. Start the terminal.
3. Run the command:
  ```bash
  export AWS_ACCESS_KEY_ID=(your access key id) && export AWS_SECRET_ACCESS_KEY=(your secret access key)
  ```

### 5. Install Terraform in IDE

1. Go the Hashicorp Terraform site and install for VSCode https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform

### 6. Clone Repo

1. Go to: https://github.com/williammcintosh/aws-terraform-project 
2. Download the code and upload it using your favorite IDE.
3. Alternatively, run the command:
  ```bash
  git@github.com:williammcintosh/aws-terraform-project.git
  ```

### 7. Apply in /s3

This part gets the storage setup for our terraform states and locks.

1. Navigate to `live/global/s3`
2. Comment out the block below in `main.tf`, save:
  ```rust
  # terraform {
  #     backend "s3" {
  #         key = "global/s3/terraform.tfstate"
  #     }
  # }
  ```
3. Run `terraform init` (not `just init`)
4. Run `terraform apply` (not `just apply`)
5. Doing this should build the S3 bucket and dynamodb in AWS console:
        * Search for “S3” or “dynamodb” in AWS console to view them.
7. Uncomment out the 'terraform' block below, save.
  ```rust
  terraform {
      backend "s3" {
          key = "global/s3/terraform.tfstate"
      }
  }
  ```
8. Run 'just init' (not `terraform init`)
9. Run 'just apply' (not `terraform apply`)

### 8. Create postgres Login

In these steps, we are creating a postgres database that will require an AWS Secret to allow our terraform code to log in. We cannot create the AWS secret until we first have the postgres db setup - creating a chicken and the egg problem. In order to get our setup started with begin with using local environment variables to create the postgres database, then transition to using AWS secrets once it's created.

1. Write a unique username and password for your database using your favorite password generator.
2. Store the username and password in your favorite password storage software like keychain.
3. Run these bash commands to set the environment variables:
  ```bash
  export TF_VAR_db_username=ACTUAL_DB_USERNAME && export TF_VAR_db_password=ACTUAL_DB_PASSWORD
  ```
4. Navigate to “live/stage/data-stores/postgres/variables.tf”
5. Uncomment these two blocks of code:
  ```yaml
  variable "db_username" {
      description = "The username for the database"
      type        = string
      sensitive   = true
  }
  
  variable "db_password" {
      description = "The password for the database"
      type        = string
      sensitive   = true
  }
  ```
6. Update the name of the actual database by navigating to “live/stage/data-stores/postgres/variables.tf”
7. Change the variable “your_actual_database_name” to a name that you’d like to make for the database.

### 9. Apply in /postgres

1. Navigate to `live/stage/data-stores/postgres`
2. Run 'just init' (not `terraform init`)
3. Run 'just apply' (not `terraform apply`)

### 10. Create Postgres Secret in AWS

In your AWS console navigate to:

1. AWS Secrets Manager > click on [Store New Secret].
2. Make sure “Credentials for Amazon RDS database” is selected.
3. Fill out the “user name” and “password” fields with the values you set from step 8.
4. Click next
5. Make sure the “secret name” is set to “db_creds”
6. Save

### 11. Apply in /postgres

1. Navigate to `live/stage/data-stores/postgres`
2. Run 'just init' (not `terraform init`)
3. Run 'just apply' (not `terraform apply`)

### 12. Use AWS Secrets

Our postgres database is currently using environment variables for the username and password, but in order to get our rust web application to work we need to allow our postgres database work using AWS secrets for the username and password. To do that, follow these steps:

1. Navigate to “live/stage/data-stores/postgres/variables.tf”
2. Comment out these two blocks of code, like this:
  ```yaml
  # variable "db_username" {
  #     description = "The username for the database"
  #     type        = string
  #     sensitive   = true
  # }
  
  # variable "db_password" {
  #     description = "The password for the database"
  #     type        = string
  #     sensitive   = true
  # }
  ```

### 13. Apply in /rust-backend

1. Navigate to `live/stage/services/rust_backend`
2. Run 'just init' (not `terraform init`)
3. Run 'just apply' (not `terraform apply`)

### 14. Open App URL

1. Open your browser
2. Copy the output “app_url” from following the previous steps
3. Paste the app_url into the browser
4. Append onto it a colon and 3000 `:3000`
5. It’ll look like this:
  ```bash
  http://load-balancer-dev-123456789.us-east-2.elb.amazonaws.com:3000/
  ```

# Using Application

### Accessing Postgres

1. Install “psql” https://www.postgresql.org/download/ 
2. You will need the following variables and how to get them in AWS console:
  * RDS_ENDPOINT : `RDS > Databases > Click on your database > Locate "Endpoint"`
  * PORT : `RDS > Databases > Click on your database > Locate "Port"`
  * DATABASE_USERNAME : `AWS Secrets Manager > Secrets > db_creds > "Retrieve secret value"`
  * DATABASE_NAME : `RDS > Databases > Click on your database > Click the "Configuration" tab > Locate "DB name"`
  * DATABASE_PASSWORD : `AWS Secrets Manager > Secrets > db_creds > "Retrieve secret value"`
3. Run the command template like this:
  ```bash
  psql -h RDS_ENDPOINT -p PORT -U DB_USERNAME -d DB_NAME
  ```
  It should turn into this when you fill out the fields:
  ```bash
  psql -h mcintosh-terraform-db01234567891234567800000001.qwertyuiopas.us-east-2.rds.amazonaws.com -p 5432 -U actual_database_username -d actual_database_name
  ```
At this point you’ll be prompted to enter the password.
You can do things like check the databases or insert databases into it https://www.geeksforgeeks.org/postgresql-psql-commands/

# Troubleshooting

### Test Container Locally

1. Navigate to `live/stage/services/rust_backend`
2. Run the command `docker build -t rust_backend . && docker run -p 3000:3000 rust_backend`
3. Once that’s complete, go to http://localhost:3000 on your browser.

