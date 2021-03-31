module "backend_bucket" {
  source      = "../../../modules/aws/s3"
  #source      = "git::git@github.com:rmemory/terraform_modules.git//aws/s3?ref=v0.0.4"
  bucket_names = ["1547765456n44a36-tf-state-random-bucket-name"] # Also update the bucketname in backend.hcl

  providers = {
    aws = aws.us-east-1
  }
}

locals {
  hash_key_name = "LockID"
}

module "backend_lock_table" {
  source        = "../../../modules/aws/dynamodb"
  # source        = "git::git@github.com:rmemory/terraform_modules.git//aws/dynamodb?ref=v0.0.4"
  table_name    = "tf_state_locks"
  hash_key_name = local.hash_key_name
  billing_mode  = "PAY_PER_REQUEST"
  attributes    = [{
    name = local.hash_key_name
    type = "S"
  }]

  providers = {
    aws = aws.us-east-1
  }
}
