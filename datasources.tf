# Get the VPC details using aws_vpc
data "aws_vpc" "mz_kafka_vpc" {
  id = var.mz_kafka_vpc_id
}

# Subnet IDs
data "aws_subnet" "mz_kafka_subnet" {
  for_each = toset(var.mz_kafka_brokers[*].subnet_id)
  id       = each.value
}
