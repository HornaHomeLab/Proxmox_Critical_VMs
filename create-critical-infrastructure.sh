#!/bin/sh

root_dir_path=$(pwd)

secrets_dir_path="$root_dir_path/secrets"
proxmox_pass_file="$secrets_dir_path/proxmox_password.txt"
vault_root_token_file="$secrets_dir_path/vault_root_token.txt"
sh_pass_file="$secrets_dir_path/sh_password.txt"

if [ ! -f "$secrets_dir_path" ]; then
    mkdir "$secrets_dir_path"
fi

if [ ! -f "$proxmox_pass_file" ]; then
    echo "Enter default proxmox user password: "
    read -r user_input
    # shellcheck disable=SC3037
    echo -n "$user_input" > "$proxmox_pass_file"
fi

if [ ! -f "$sh_pass_file" ]; then
    echo "Enter SH user password: "
    read -r user_input
    # shellcheck disable=SC3037
    echo -n "$user_input" > "$sh_pass_file"
fi

if [ ! -f "$vault_root_token_file" ]; then
    echo "Enter HashiCorp Vault token: "
    read -r user_input
    # shellcheck disable=SC3037
    echo -n "$user_input" > "$vault_root_token_file"
fi

if [ ! -f "$secrets_dir_path/id_rsa" ]; then
    # Generate a private key
    ssh-keygen -t rsa -b 4096 -C "proxmox" -f "$secrets_dir_path/id_rsa"
fi

# Provision VMs
cd ./VM || exit 1
terraform init
terraform apply
cd ..
sleep 30


# Configure VMs
cd ./ansible || exit 1
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
ansible-playbook ./main.yaml -u proxmox -i ./hosts --private-key "$secrets_dir_path/id_rsa" 
cd ..
sleep 30

# Provision Docker Containers
cd ./Docker || exit 1
terraform init
terraform apply
cd ..

# rm -fr "$secrets_dir_path"