module "instance" {
  source = "../../../../../modules/aws/ec2"
  name = local.cluster_name
  subnet_ids = data.aws_subnet_ids.public.ids
  server_port = local.server_port
  application_port = local.application_port
  security_group_ids = [aws_security_group.alb-sg.id]
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  providers = {
      aws = aws.us-east-1
  }
}