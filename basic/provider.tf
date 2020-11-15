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

# AKIAV4LZZODF7XC22C7D
# xmfDLcK/LsAwAccm+dtEQCBjd8RIb1Io093jMz4L

