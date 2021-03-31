# Create AWS user

# Install terraform and ansible
1) One time only tasks: 

a) If you don't already have an AWS account, create one:

https://portal.aws.amazon.com/gp/aws/developer/registration/index.html

b) Install the AWS cli 

sudo apt install pip3

Install to the Python user install directory for your platform. Typically ~/.local/

$ pip3 install awscli --user
$ aws --version
aws-cli/1.18.178 Python/3.8.5 Linux/5.4.0-53-generic botocore/1.19.18

To update the AWS CLI, use the following:

pip3 install --upgrade awscli

c) Install ansible

$ sudo apt update
$ sudo apt install software-properties-common
$ sudo apt-add-repository --yes --update ppa:ansible/ansible
$ sudo apt install ansible
$ ansible --version
ansible 2.10.3

d) Install terraform

Look for the latest version at https://releases.hashicorp.com/terraform/ 

In this example, it will be version 0.13.5. 

$ wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
$ sudo unzip ./terraform_0.13.5_linux_amd64.zip -d /usr/local/bin
$ terraform --version
Terraform v0.13.5

e) Install boto3

Boto is the Amazon Web Services (AWS) SDK for Python. It enables Python developers to create, configure, and manage AWS services, such as EC2 and S3. Boto provides an easy to use, object-oriented API, as well as low-level access to AWS services.

$ pip3 install boto3 --user
$ pip3 show boto3 | grep Version
Version: 1.16.30
$ pip3 install --upgrade boto3

2) In the AWS Management Console (via the web) create a new user to perform terraform provisioning. In other words, don't use the root account to provision resources. You can use the root user, but it's best practice to create separate users create a separate user with a proper permissions to perform the job (in this case, provisioning of resources using Terraform). Actually, it is best practice to create groups, assign policies to those groups with the correct permissions for the group, and assign users to that group. But, we'll skip the creation of groups here.

a) Create a policy containing the permissions for the terraform provisioning. To do so log into the AWS console, go to the IAM dashboard. Select Policies - Create Policy -> JSON. Copy and paste the entire contents of the iam_policy_examples/my_terraform.json file from this repo into the editor. Give the policy a name, eg. MyTerraformPolicy.

b) Next, select Users -> Add user. Give the new user a name, eg. MyTerraformUser. Give the new user both Programmatic and AWS Management Console access. Attach the previously created MyTerraformPolicy to the user "Attach existing policies directly". After attaching the policy, create the user. Be sure to download the csv containing the access key, access secret, and login password.

3) Configure AWS cli to use the newly created account

$ aws configure
Enter the Access key ID and Secret access key values obtained above.
Enter a region of us-east-1
Enter output of json

The output is stored in the ~/.aws directory.

Next, test the connectivity: 

$ aws ec2 describe-instances
{
    "Reservations": []
}

# Create S3 bucket and dynamodb table for terraform locking

The bucket name is found inside of the live/backend.hcl, but the same filename is used elsewhere in the scripts to extract state info for use by resources.

cd ~/projects/terraform_deploy/live/global/backend
open provider.tf and comment out terraform/backend block
$ terraform init
$ terraform apply --auto-approve
$ rm -fr .terraform
open provider.tf and uncomment out terrform/backend block
$ terraform init -backend-config=../../backend.hcl
enter 'yes' when prompted to copy state to s3
$ rm terraform.tfstate* 
$ terraform refresh

# Create VPCs
## Stage VPC
$ cd ~/projects/terraform_deploy/live/stage/vpc
$ terraform init -backend-config=../../backend.hcl
$ terraform apply --auto-approve

## Production VPC
cd ~/projects/terraform_deploy/live/production/vpc
$ terraform init -backend-config=../../backend.hcl
$ terraform apply --auto-approve

## Jenkins VPC
$ cd ~/projects/terraform_deploy/live/mgmt/jenkins
$ terraform init -backend-config=../../backend.hcl
$ terraform apply --auto-approve

# Databases

Using console, add mysql-master-password-stage to secrets manager.
copy the ARN for the secret and paste it into the "aws_secretsmanager_secret_version" "db_password" data resource in the database.

cd ../data-stores/mysql
terraform init -backend-config=../../../global/s3/backend.hcl
terraform apply --auto-approve

# Applications

## EC2 with autoscaling

### Stage
$ cd ~/projects/terraform_deploy/live/stage/services/webserver-cluster
$ terraform init -backend-config=../../../backend.hcl
$ terraform apply --auto-approve

### Production
$ cd ~/projects/terraform_deploy/live/production/services/webserver-cluster
$ terraform init -backend-config=../../../backend.hcl
$ terraform apply --auto-approve

## Blue/Green release

https://www.hashicorp.com/blog/terraform-feature-toggles-blue-green-deployments-canary-test

https://medium.com/@endofcake/using-terraform-for-zero-downtime-updates-of-an-auto-scaling-group-in-aws-60faca582664

## ECS/Fargate

# Useful commands

## Terraform
$ terraform fmt

Will format all of the templates in the working directory for readability and consistency.

$ terraform validate

Checks code for syntax mistakes, misconfigured resources.

$ terraform plan

Creates the execution plan. Calculates the dellta between what is currently provisionied and what will be provisioned. Use the -out flag to create a plan file.

$ terraform apply

Applies the plan. Use the -y command to skip approval step.


## Anisible

$ ansible-doc -t inventory -l
$ ansible-doc -t inventory -l aws_ec2
$ ansible-galaxy collection install amazon.aws
$ ansible-galaxy collection install community.crypto
$ ansible-inventory -i tf_aws_ec2.yml --graph
$ ansible-playbook ansible-templates/gen_ssh_key.yml

9) Inside of ansible.cfg

```
[defaults]
enable_plugins = aws_ec2
inventory = ./ansible_templates/inventory_aws
interpreter_python = auto_silent 
```

11) To enable logging in terraform

export TF_LOG=TRACE
export TF_LOG_PATH=/my/path/logfile.txt

export ANSIBLE_DEBUG # can display sensitive information in logs
export ANSIBLE_VERBOSITY=2

Also, can use the following flags
-v 
-vv