# The `StrictHostKeyChecking=no` option in SSH prevents SSH from asking for confirmation when connecting to a new host for the first time.  

# ### **Why is this needed?**  
# By default, when you connect to a new server via SSH, it asks:  
# ```
# The authenticity of host 'X.X.X.X (X.X.X.X)' can't be established.
# ECDSA key fingerprint is SHA256:xxxxxxx.
# Are you sure you want to continue connecting (yes/no)?
# ```
# This happens because SSH stores the known host fingerprints in `~/.ssh/known_hosts`. If the host is new or its fingerprint has changed, SSH warns you about it.  

# ### **How `StrictHostKeyChecking=no` helps**  
# Setting `StrictHostKeyChecking=no` **automatically accepts the host key** and prevents SSH from prompting the user for confirmation. This is useful in automation scripts where human input is not possible.

# ### **Potential Risks**
# - It **disables host authenticity checks**, making it easier for a **Man-in-the-Middle (MITM) attack** to succeed.
# - If a malicious server with the same IP replaces your instance, SSH will not warn you.

# ### **Safer Alternatives**
# Instead of disabling host key checking, you can use:
# 1. **Add the host key automatically to known_hosts**:  
#    ```sh
#    ssh -o StrictHostKeyChecking=accept-new -i my-key.pem user@server
#    ```
#    - This will **only accept new hosts**, but warn if an existing fingerprint changes.
#    - Available in OpenSSH 7.6+.

# 2. **Manually specify a known hosts file** (avoids modifying the global known_hosts file):  
#    ```sh
#    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i my-key.pem user@server
#    ```
#    - This means SSH will never store the host fingerprint.

# ### **Best Practice for Terraform and Automation**
# - In temporary automation scripts, `StrictHostKeyChecking=no` is fine.
# - For production environments, use `accept-new` or manually manage `known_hosts`.

# Would you like me to update your script to follow a safer approach? 🚀

provider "aws" {
  region = "us-east-1"
}
variable "amiid" {
  default = file("../amiidoutput.txt")
}

# Read the output file
data "local_file" "vpc_output" {
  filename = "../vpc_output.txt"
}
data "local_file" "basedata" {
  filename = "../base_data.txt"
}

# Parse the content of the file and extract values
locals {
  vpc_id                      = regex("vpc_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_1_id          = regex("public_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_2_id          = regex("public_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_1_id         = regex("private_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_2_id         = regex("private_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  security_group_id           = regex("sg1 = (\\S+)", data.local_file.basedata.content)[0]
  base_ami                    = regex("bami = (\\S+)", data.local_file.basedata.content)[0]
}

######################
# EC2 Instance and AMI
######################
resource "aws_instance" "my_ec2" {
  ami           = local.base_ami  # Replace with your base AMI ID
  instance_type = "t2.micro"
  key_name      = "malcom1"  # Replace with your actual key name

  vpc_security_group_ids = [local.security_group_id]  # Using the security group ID from the file

  subnet_id = local.public_subnet_1_id  # Launching EC2 in the first public subnet

  tags = {
    Name = "MyInstance"
  }
}

# Step 2: Create AMI from the EC2 Instance (if create_ami=true)
resource "aws_ami_from_instance" "my_ami" {
  count              = var.create_ami ? 1 : 0  # Only create AMI if variable is true
  name               = var.amiid
  source_instance_id = aws_instance.my_ec2.id
}

# Step 3: Output the Public IP
output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

output "ami_id" {
  value = aws_ami_from_instance.my_ami.id
}

resource "local_file" "ami_outputs" {
  content = <<EOT

ec2_public_ip = ${aws_instance.my_ec2.public_ip}
ami_id = ${aws_ami_from_instance.my_ami.id}
EOT

  filename = "../ami_output.txt"
}

# terraform apply -var="create_ami=false" -auto-approve
# terraform apply -var="create_ami=true" -auto-approve
