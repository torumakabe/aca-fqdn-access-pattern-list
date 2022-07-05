variable "prefix" {
  type = string
}

variable "log_analytics" {
  type = object({
    workspace = object({
      id  = string
      key = string
    })
  })
  sensitive = true
}

variable "admin_username" {
  type      = string
  default   = "adminuser"
  sensitive = true
}
