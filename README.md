# Materialize + PrivateLink + Kafka

> **Warning**
> This is provided on a best-effort basis and Materialize cannot offer support for this module

This repository contains a Terraform module that configures a PrivateLink endpoint for an existing Kafka cluster running on AWS to connect to Materialize.

The module creates the following resources:
- Target group for each Kafka Broker
- Network Load Balancer for the Kafka cluster
- TCP listener for the NLB to forward traffic to each target group
- A VPC endpoint service for your Kafka cluster

> **Note**
> If you have an MSK cluster, you can use the [terraform-aws-msk-privatelink](https://github.com/MaterializeInc/terraform-aws-msk-privatelink) module instead.

## Important Remarks

- The Kafka cluster must be in the same VPC as the PrivateLink endpoint.
- Review this module with your Cloud Security team to ensure that it meets your security requirements.
- Finally, after the Terraform module has been applied, you will need to make sure that the Target Groups heatlth checks are passing. As the NLB does not have security groups, you will need to make sure that the NLB is able to reach the Kafka brokers by allowing the subnet CIDR blocks in the security groups of the Kafka cluster.

## Usage

### Variables

Start by copying the `terraform.tfvars.example` file to `terraform.tfvars` and filling in the variables:

```
cp terraform.tfvars.example terraform.tfvars
```

| Name | Description | Type | Example | Required |
|------|-------------|:----:|:-----:|:-----:|
| mz_kafka_cluster_port | The port that the Kafka cluster is listening on | string | `9092` | yes |
| mz_kafka_vpc_id | The VPC ID of the Kafka cluster | string | `vpc-1234567890abcdef0` | yes |
| mz_kafka_brokers | The list of Kafka brokers | list | `[{"broker_id" = 1, "broker_ip" = "172.31.49.181", "subnet_id" = "subnet-08be71ead81dd5e22"}, {"broker_id" = 2, "broker_ip" = "172.31.83.78", "subnet_id" = "subnet-0b4256c2fe535c158"}]` | yes |

### Apply the Terraform Module

```
terraform apply
```

### Output

After the Terraform module has been applied, you will see the following output.

You can follow the instructions in the output to configure the PrivateLink endpoint and the Kafka connection in Materialize:

```sql
  - mz_kafka_endpoint_sql             = <<-EOT
            -- Create the private link endpoint in Materialize
            CREATE CONNECTION privatelink_svc TO AWS PRIVATELINK (
                SERVICE NAME 'com.amazonaws.vpce.us-east-1.vpce-svc-1234567890abcdef0',
                AVAILABILITY ZONES ("use1-az1", "use1-az2")
            );

            -- Get the allowed principals for the VPC endpoint service
            SELECT principal
                FROM mz_aws_privatelink_connections plc
                JOIN mz_connections c ON plc.id = c.id
                WHERE c.name = 'privatelink_svc';

            -- IMPORTANT: Get the allowed principals, then add them to the VPC endpoint service

            -- Create the connection to the Kafka cluster
            CREATE CONNECTION kafka_connection TO KAFKA (
                BROKERS (
                '172.31.49.181:9092' USING AWS PRIVATELINK privatelink_svc (AVAILABILITY ZONE = 'use1-az1', PORT 9001),
        '172.31.83.78:9092' USING AWS PRIVATELINK privatelink_svc (AVAILABILITY ZONE = 'use1-az2', PORT 9002)
                ),
                -- Authentication details
                -- Depending on the authentication method the Kafka cluster is using
                SASL MECHANISMS = 'SCRAM-SHA-512',
                USERNAME = 'foo',
                PASSWORD = SECRET bar
            );
    EOT
```

### Output details: Configure Materialize

Once the Terraform module has been applied, you can configure Materialize to connect to the Kafka cluster using the PrivateLink endpoint:

- Connect to the Materialize instance using `psql`
- Run the SQL statement from the output of the `terraform apply` command to configure the PrivateLink connection, example:

```sql
CREATE CONNECTION privatelink_svc TO AWS PRIVATELINK (
        SERVICE NAME 'com.amazonaws.vpce.us-east-1.vpce-svc-1234567890abcdef0',
        AVAILABILITY ZONES ("use1-az1", "use1-az2")
    );
```

- Get the allowed principals for the VPC endpoint service

```sql
SELECT principal
    FROM mz_aws_privatelink_connections plc
    JOIN mz_connections c ON plc.id = c.id
    WHERE c.name = 'privatelink_svc';
```

- Add the allowed principals to the Endpoint Service configuration in the AWS console

- Finally, run the last SQL statement from the output of the `terraform apply` command to create the Kafka connection which will use the PrivateLink endpoint, example:

```sql
    -- Create the connection to the Kafka cluster
    CREATE CONNECTION kafka_connection TO KAFKA (
                BROKERS (
                '172.31.49.181:9092' USING AWS PRIVATELINK privatelink_svc (AVAILABILITY ZONE = 'use1-az1', PORT 9001),
        '172.31.83.78:9092' USING AWS PRIVATELINK privatelink_svc (AVAILABILITY ZONE = 'use1-az2', PORT 9002)
                ),
                -- Authentication details
                -- Depending on the authentication method the Kafka cluster is using
                SASL MECHANISMS = 'SCRAM-SHA-512',
                USERNAME = 'foo',
                PASSWORD = SECRET bar
            );
```

For more information about the `CREATE CONNECTION` statement, you can check the [Materialize documentation](https://materialize.com/docs/sql/create-connection/#kafka).

After that go to your AWS console and check that the VPC endpoint service has a pending connection request from the Materialize instance which you can approve.

After the connection request has been approved, you can create a Kafka source in Materialize using the `kafka_connection` connection.

## Materialize Documentation

You can also follow the [Materialize documentation](https://materialize.com/docs/ops/network-security/privatelink/) for more information.

