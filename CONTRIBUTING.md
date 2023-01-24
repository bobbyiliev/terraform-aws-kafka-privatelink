# Contributor instructions

## Testing

### Manual testing

To test the module manually, follow these steps:

1. Login to the [AWS console](https://aws.amazon.com/).
1. Deploy a self-managed Kafka cluster in AWS with at least 2 brokers in 2 different availability zones.
1. Copy the `terraform.tfvars.example` file to `terraform.tfvars`:
    ```
    cp terraform.tfvars.example terraform.tfvars
    ```
1. Update the values in `terraform.tfvars` to match your cluster. Make sure to define an array with your Kafka broker IP addresses and their subnet IDs. For example:
    ```json
   [
        {
            "broker_id" = 1,
            "broker_ip" = "172.31.49.181",
            "subnet_id" = "subnet-some-subnet-id"
        },
        {
            "broker_id" = 2,
            "broker_ip" = "172.31.83.78",
            "subnet_id" = "subnet-some-subnet-id2"
        }
    ]
    ```
1. Create the resources:
    ```
    terraform apply
    ```
1. After the resources have been created, go to the Target Groups in the AWS console and make sure that the health checks are passing. If they are not, you will need to add the subnet CIDR blocks of your Kafka cluster to the security groups of your Kafka cluster. For more information, see [this AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-troubleshooting.html).
1. Next, run the queries in the output to create the connection in Materialize.
1. Finally, in your AWS console, under the Endpoint Service that was created, approve the connection request from the Materialize instance and check that the connection is active.
1. You can now create a Kafka source in Materialize using the connection name from the output.
1. Finally, drop the connection in Materialize and run `terraform destroy` to clean up the resources.

## Cutting a new release

Perform a manual test of the latest code on `main`. See prior section. Then run:

    git tag -a vX.Y.Z -m vX.Y.Z
    git push origin vX.Y.Z
