#!/bin/bash

echo "Installing Vault Enterprise"

#!/bin/bash
export instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
export internal_ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
export external_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
sudo apt update && sudo apt install gpg
sudo apt install jq
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault-enterprise=${vault_version}
sudo systemctl enable vault.service
sudo echo ${vault_license} > /etc/vault.d/vault.hclic
sudo chown vault:vault /etc/vault.d/vault.hclic
sudo cp /etc/vault.d/vault.hcl /etc/vault.d/vault.hcl_orig
sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOT
ui = true
mlock = false
cluster_addr  = "http://$internal_ip:8201"
api_addr      = "http://$internal_ip:8200"
log_level = "trace"

storage "raft" {
  path = "/opt/vault/data"
  node_id = "$instance_id"
  retry_join {
    auto_join = "provider=aws addr_type=private_v4 region=${region} tag_key=vault-cluster tag_value=${vault_cluster}"
    auto_join_scheme = "http"
  }
}


listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

# Enterprise license_path
# This will be required for enterprise as of v1.8
license_path = "/etc/vault.d/vault.hclic"

seal "awskms" {
  region = "${region}"
  kms_key_id = "${kms_key_id}"
}

replication {
  resolver_discover_servers = true
  best_effort_wal_wait_duration = "2s"
}



EOT

sudo chown -R vault:vault /etc/vault.d/*
sudo systemctl start vault.service
sudo echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/ubuntu/.bashrc
