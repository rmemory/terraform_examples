# terraform init -backend-config=<path to this file>/backend.hcl

bucket         = "1547765456n44a36-tf-state-random-bucket-name"
region         = "us-east-1"
profile        = "default"
dynamodb_table = "tf_state_locks"
encrypt        = true