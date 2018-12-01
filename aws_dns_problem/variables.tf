variable enable_dns_support {}
variable enable_dns_hostnames {}

variable vpc_cidr {
  default = "10.1.0.0/16"
}
variable public_cidr {
  default = "10.1.1.0/24"
}
variable private_cidr1 {
  default = "10.1.2.0/24"
}
variable private_cidr2 {
  default = "10.1.3.0/24"
}
variable engine_name {
  default = "postgres"
}
variable engine_version {
  default = "10.4"
}
variable license_model {
  default = "postgresql-license"
}
variable port {
  default = 5432
}
variable database_name {
  default = "test"
}
variable username {
  default = "jayground"
}
variable password {
  default = "helloworld)("
}
variable allocated_storage {
  default = 20
}
variable keypair {
  default = "jayground"
}