#!/bin/bash

# Step 1: Initialize Terraform
terraform init
terraform validate
terraform plan

# Step 2: Apply Terraform to Create EC2 Instance
terraform apply -var="create_ami=false" -auto-approve

# Step 3: Get Instance Public IP
INSTANCE_IP=$(terraform output -raw ec2_public_ip)

# Step 4: Wait for SSH to be available
echo "Waiting for instance to be ready..."
while ! ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "echo 'Instance is ready'"; do
  sleep 5
done
echo "finally done waiting"


# Step 5: Copy the Password File & Script to the EC2 Instance
scp -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem my_password_file.txt ubuntu@$INSTANCE_IP:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem my_script.sh ubuntu@$INSTANCE_IP:/home/ubuntu/

echo "done 1"
# Step 6: Execute the Script on the EC2 Instance
ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "chmod +x /home/ubuntu/my_script.sh"
ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "/bin/bash /home/ubuntu/my_script.sh"

echo "done 2"
# Step 7: Create an AMI using Terraform
terraform apply -target=aws_ami_from_instance.my_ami -var="create_ami=true" -auto-approve
echo "done 3"
echo "AMI creation complete!"
terraform output -raw my_output_variable > ../ami-id.txt


