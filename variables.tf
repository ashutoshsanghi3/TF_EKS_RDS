variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "stack_name" {
  type    = string
  default = "stackset"
}

variable "my_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
  validation {
    condition     = contains(["10.0.0.0/16", "20.0.0.0/18"], var.my_vpc_cidr)
    error_message = "Allowed CIDR blocks: 10.0.0.0/16 or 20.0.0.0/18"
  }
}

variable "my_db_subnet_group_name" {
  type    = string
  default = "mydb-subnet-group"
}

variable "my_db_name" {
  type    = string
  default = "mysqldatabase"
}

variable "my_db_username" {
  type    = string
  default = "admin"
}

variable "my_db_password" {
  type    = string
  default = "adminadmin"
  sensitive = true
}

variable "subnet_config" {
  type = map(object({
    public_az1_cidr       = string
    private_az1_cidr1     = string
    private_az1_cidr2     = string
    public_az2_cidr       = string
    private_az2_cidr1     = string
    private_az2_cidr2     = string
  }))
  default = {
    Vpc10 = {
      public_az1_cidr   = "10.0.0.0/20"
      private_az1_cidr1 = "10.0.16.0/20"
      private_az1_cidr2 = "10.0.32.0/20"
      public_az2_cidr   = "10.0.48.0/20"
      private_az2_cidr1 = "10.0.64.0/20"
      private_az2_cidr2 = "10.0.80.0/20"
    }
    Vpc20 = {
      public_az1_cidr   = "20.0.0.0/22"
      private_az1_cidr1 = "20.0.4.0/22"
      private_az1_cidr2 = "20.0.8.0/22"
      public_az2_cidr   = "20.0.12.0/22"
      private_az2_cidr1 = "20.0.16.0/22"
      private_az2_cidr2 = "20.0.20.0/22"
    }
  }
}
