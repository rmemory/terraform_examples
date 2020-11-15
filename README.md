1) Using the Amazon web interface, create an account

https://portal.aws.amazon.com/gp/aws/developer/registration/index.html

Once logged in to the account, using the menu for the user, select My Security Credentials. Create an access key, and record both the Access key ID and Secret access key values.

2) Install the AWS cli (one time only) 

$ pip3 install awscli --user
$ aws --version
aws-cli/1.18.178 Python/3.8.5 Linux/5.4.0-53-generic botocore/1.19.18

3) Configure AWS cli to use the newly created account

$ aws configure
Enter the Access key ID and Secret access key values obtained above.
Enter a region of us-east-1
Enter output of json

The output is stored in the ~/.aws directory.

4) Install ansible (one time only)

$ sudo apt install ansible

5) In the AWS console for the account, navigate to IAM. Select "Policies". Select "Create Policy". Select the JSON tab, paste in the contents of custom_policy.json. Give it a name and tag of your choice, such as MyTFPolicy, and create the policy.

6) Still in the IAM section in the AWS console, select Create User. Give the user a name. Select Programmatic access. Select Attach existing policies directly. Search for the policy name created in the previous step and select it. Add a tag. Create the user. Record the Access key ID and Secret access key values.

7) Using the AWS cli, create an S3 bucket to store the terraform state:

$ aws s3api create-bucket --bucket terraformbucket12348765
{
    "Location": "/terraformbucket12348765"
}

8) Create a directory for the project. In that directory create a backend.tf file

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

9) Now run terraform init

You should see the following message: 

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

10) Next, create a provider.tf file with a provider entries for each region used by the application. But, first create a vars.tf.

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

$ terraform init