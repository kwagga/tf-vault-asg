variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for launch template"
  default     = "t3a.micro"
}

variable "application_port" {
  type        = string
  description = "Application port"
}

variable "api_port" {
  type        = string
  description = "Vault API port"
}

variable "cluster_port" {
  type        = string
  description = "Vault cluster port"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "system_name" {
  type        = string
  description = "System name that the infrastructure is created for"
}

variable "user_data" {
  type        = string
  description = "User data to be applied to launch template"
}

variable "node_name_prefix" {
  type        = string
  description = "Node name prefix"
  default     = "vault"
}

variable "ssh_key_name" {
  type        = string
  description = "SSH key name"
}

variable "vault_version" {
  type        = string
  description = "Version of Vault Enterprise to install"
}

variable "vault_license" {
  type        = string
  description = "Vault Enterprise Lisence"
}

variable "asg_desired_cap" {
  type        = string
  description = "ASG Desired capacity"
}

variable "asg_max_cap" {
  type        = string
  description = "ASG Max capacity"
}

variable "asg_min_cap" {
  type        = string
  description = "ASG Min capacity"
}