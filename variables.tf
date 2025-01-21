variable "name" {
  description = "base name of resources to be created"
  type        = string
}

variable "environment" {
  description = "environment name associated with resources to be created"
  type        = string
  default     = "test"
}

variable "cost_center" {
  description = "cost center to charge for resource"
  type        =  string
  default      = "internal"
}

variable "owner" {
  description = "owner of the resources"
  type        =  string
  default     = "admin" 
}

variable "region" {
  description = "AWS region to use"
  type        = string
  default     = "us-west-2"
  validation {
    condition = contains([
      "us-west-2",
      "us-east-1",
      "ca-central-1"
    ], var.region)
    error_message = "The region variable must be set to us-west-2, us-east-1, or ca-central-1."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
  type        = string
  default     = "10.100.0.0/16"
}

variable "cidr_private_subnets" {
  description = "CIDR blocks for Private Subnets"
  type        = list(any)
  default     = ["10.100.32.0/19", "10.100.64.0/19", "10.100.96.0/19"]
}

variable "cidr_public_subnets" {
  description = "CIDR blocks for Public Subnets"
  type        = list(any)
  default     = ["10.100.0.0/22", "10.100.4.0/22", "10.100.8.0/22"]
}

variable "enable_public_subnets" {
  description = "whether to enable public subnets"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "list of availbility zones to use"
  type        = list(any)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

locals {
  my_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
  }
}