# tf-vault-asg
## Vault Enterprise cluster in an AWS Auto Scaling Group.
This will deploy a Vault Enterprise cluster in an AWS ASG. Deploy both projects in order to configure Disaster Recovery or Performance Replication.

Post deployment you'll have:
- An AWS ASG
- An ELB (DNS and TCP port 8200 listener)
- An ELB target group (forwarding traffic to instances)
- An AWS KMS Key
- Vault Enterprise installed and configured to auto-unseal using the KMS key as well as raft `auto_join`

# Disclaimer
This is extremely crude and there is probably a thousand better ways to do this, but I'm still learning so don't judge :)

**Please do not use this for production employments. This is for lab/testing purposes only.**
