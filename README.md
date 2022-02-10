# S3-Lambda-DynamoDB-Terraform
A simple system that will listen to a newObjectCreated event of s3 and will summarize the s3 objects in dynamodb
### Prerequisities
- Install [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Install [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Configure ```aws-cli``` with your aws acount keys
> **NB** You can use an IAM user and configure aws cli with the keys of that IAM user. Name your profile as your wish.
### Commands
- ```terraform init```
- ```terraform plan```
- ```terraform apply```
