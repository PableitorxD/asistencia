variable "ambiente" {
  default = "dev"
}
variable "db_password" {
  default = "secreto123"
  sensitive = true
}