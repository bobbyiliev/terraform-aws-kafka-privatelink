# For each Kafka broker, create a target group
resource "aws_lb_target_group" "mz_kafka_target_group" {
  count       = length(var.mz_kafka_brokers)
  name        = "mz-kafka-target-group-${count.index}"
  port        = var.mz_kafka_cluster_port
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.mz_kafka_vpc.id
  target_type = "ip"
}

# For each Kafka broker, attach a target to the target group
resource "aws_lb_target_group_attachment" "mz_kafka_target_group_attachment" {
  count            = length(var.mz_kafka_brokers)
  target_group_arn = aws_lb_target_group.mz_kafka_target_group[count.index].arn
  target_id        = var.mz_kafka_brokers[count.index].broker_ip
}

# Create a network Load Balancer
resource "aws_lb" "mz_kafka_lb" {
  name                             = "mz-kafka-lb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = var.mz_kafka_brokers[*].subnet_id
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "mz-kafka-lb"
  }
}

# Create a tcp listener on the Load Balancer for each Kafka broker
# with a unique port and forward traffic to the target group
resource "aws_lb_listener" "mz_kafka_listener" {
  count             = length(var.mz_kafka_brokers)
  load_balancer_arn = aws_lb.mz_kafka_lb.arn
  port              = 9001 + count.index
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mz_kafka_target_group[count.index].arn
  }
}

# Create VPC endpoint service for the Load Balancer
resource "aws_vpc_endpoint_service" "mz_kafka_lb_endpoint_service" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.mz_kafka_lb.arn]
  tags = {
    Name = "mz-kafka-lb-endpoint-service"
  }
}

# Return the VPC endpoint service name
output "mz_kafka_lb_endpoint_service_name" {
  value = aws_vpc_endpoint_service.mz_kafka_lb_endpoint_service.service_name
}
