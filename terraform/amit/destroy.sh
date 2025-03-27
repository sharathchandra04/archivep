[ -f ../ami_output.txt ] && cp ../ami_output.txt ../ouputfiles/ami_output_backup.txt
terraform destroy -auto-approve
