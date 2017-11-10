
rm -f oasis.out
rm -f terraform.tfstate

terraform plan --out="oasis.out" --var "ssh_key_name=OasisProject" --var "ssh_key_path=~/.ssh/oasis.pem"
