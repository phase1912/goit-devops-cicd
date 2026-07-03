variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}
