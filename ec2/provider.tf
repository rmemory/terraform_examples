provider "aws" {
    region = "${var.AWS_REGION}"

  assume_role {
      role_arn = "arn:aws:iam::${var.ROLE_ARN_ID}:role/cp-aws-sandbox-power-user-role"
      # You'll want to replace the arn with your own account arn with the proper permissions.
      # i.e. "arn:aws:iam::<your account number here>:role/cp-aws-sandbox-power-user-role"
  }
}