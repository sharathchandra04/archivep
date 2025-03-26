# variables.tf
variable "create_ami" {
  description = "Set to true to create an AMI, false to skip AMI creation"
  type        = bool
  default     = false  # Set it to false by default to skip AMI creation
}
