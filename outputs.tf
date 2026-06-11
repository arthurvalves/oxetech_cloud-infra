output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "web_sg_id" {
  value = module.security.web_sg_id
}

output "rds_sg_id" {
  value = module.security.rds_sg_id
}

output "ec2_public_ip" {
  value = module.compute.ec2_public_ip
}

output "api_gateway_url" {
  value = module.compute.api_gateway_url
}

output "rds_endpoint" {
  value     = module.storage.rds_endpoint
  sensitive = true
}

output "s3_bucket_name" {
  value = module.storage.s3_bucket_name
}

output "dynamodb_table_name" {
  value = module.storage.dynamodb_table_name
}