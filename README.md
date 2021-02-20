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


2) In the AWS Management Console (via the web) create a new user to perform terraform provisioning. In other words, don't use the root account to provision resources. You can use the root user, but it's best practice to create separate users create a separate user with a proper permissions to perform the job (in this case, provisioning of resources using Terraform). Actually, it is best practice to create groups, assign policies to those groups with the correct permissions for the group, and assign users to that group. But, we'll skip the creation of groups here.

a) Create a policy containing the permissions for the terraform provisioning. To do so log into the AWS console, go to the IAM dashboard. Select Policies - Create Policy -> JSON. Copy and paste the entire contents of the my_terraform.json file from this repo into the editor. Give the policy a name, eg. MyTerraformPolicy.

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

4) Using the AWS cli, create an S3 bucket to store the terraform state:

$ aws s3api create-bucket --bucket terraformbucket12348765 --region us-east-1
{
    "Location": "/terraformbucket12348765"
}

5) Create a directory for the project. In that directory create a `backend.tf` file

```
terraform {
  required_version = ">=0.13.0"
  required_providers {
    aws = ">=3.0.0"
  }
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "terraformstatefile"
    bucket  = "terraformbucket12348765"
  }
}
```

6) Now run terraform init

Terraform init will initialize the current working directory. It need to be run before deploying infrastructure, installs proper plugins, etc.

You should see the following message: 

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

$ terraform fmt

Will format all of the templates in the working directory for readability and consistency.

$ terraform validate

Checks code for syntax mistakes, misconfigured resources.

$ terraform plan

Creates the execution plan. Calculates the dellta between what is currently provisionied and what will be provisioned. Use the -out flag to create a plan file.

$ terraform apply

Applies the plan. Use the -y command to skip approval step.

7) Next, create a provider.tf file with a provider entries for each region used by the application. But, first create a vars.tf.

```
variable "profile" {
    type    = string
    default = "default"
}

variable "region-master" {
    type    = string
    default = "us-east-1"
}

variable "region-worker" {
    type    = string
    default = "us-west-2"
}
```

Now create a provider.tf file

```
provider "aws" {
  profile    = var.profile
  region     = var.region-master
  alias      = "region-master"

}

provider "aws" {
  profile    = var.profile
  region     = var.region-worker
  alias      = "region-worker"
}
```

8) Useful anisible commands

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

10)

* backend.tf
* vars.tf
* provider.tf
* vpcs
* routing tables
* security groups

11) To enable logging in terraform

export TF_LOG=TRACE
export TF_LOG_PATH=/my/path/logfile.txt

export ANSIBLE_DEBUG
export ANSIBLE_VERBOSITY=2

-v 
-vv