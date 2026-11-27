variable "db_password" {
  type      = string
  sensitive = true
  default   = "pasta_atlas"
}

variable "allowed_origins" {
  type    = list(string)
  default = ["http://localhost:2300"]
}
