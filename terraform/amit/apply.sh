#!/bin/bash

# Step 1: Initialize Terraform
# terraform init
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
scp -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ../../backend/prodenv.sh ubuntu@$INSTANCE_IP:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem bootstrap.sh ubuntu@$INSTANCE_IP:/home/ubuntu/

echo "done 1"
# Step 6: Execute the Script on the EC2 Instance
ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "chmod +x /home/ubuntu/bootstrap.sh"
ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "chmod +x /home/ubuntu/prodenv.sh"
ssh -o StrictHostKeyChecking=no -i ~/archivep/terraform/malcom1.pem ubuntu@$INSTANCE_IP "/bin/bash /home/ubuntu/bootstrap.sh"

echo "done 2"
# Step 7: Create an AMI using Terraform
terraform apply -target=aws_ami_from_instance.my_ami -target=local_file.ami_outputs -var="create_ami=true" -auto-approve
echo "done 3"
echo "AMI creation complete!"
# terraform output -raw my_output_variable > ../ami-id.txt
[ -f ../ami_output.txt ] && cp ../ami_output.txt ../ouputfiles/ami_output_backup.txt

echo "finally it is done"
terraform state rm aws_ami_from_instance.my_ami
terraform destroy -target=aws_instance.my_ec2 -auto-approve -var="create_ami=false"
echo "terminated instance"
