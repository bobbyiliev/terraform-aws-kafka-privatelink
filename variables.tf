# AWS Details
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "default"
}
variable "aws_config_file" {
  description = "AWS config file"
  type        = list(any)
  default     = ["~/.aws/config"]
}

# List of variables that the user would need to change

# Port: 9092, or the port that you are using in case it is not 9092 (e.g. 9094 for TLS or 9096 for SASL).
variable "mz_kafka_cluster_port" {
  description = "The port of the existing kafka cluster"
}

# The VPC ID of the existing kafka cluster
variable "mz_kafka_vpc_id" {
  description = "The VPC ID of the existing kafka cluster"
}

# The list fo Kafka brokers IPs and their subnet IDs
variable "mz_kafka_brokers" {
  description = "The list fo Kafka brokers IPs and their subnet IDs"
  # default = [
  #   {
  #     "broker_id" = 1,
  #     "broker_ip" = "BROKER_1_IP_HERE",
  #     "subnet_id" = "subnet-1234567890abcdef"
  #   },
  #   {
  #     "broker_id" = 2,
  #     "broker_ip" = "BROKER_2_IP_HERE",
  #     "subnet_id" = "subnet-fedcba0987654321"
  #   }
  # ]
}
