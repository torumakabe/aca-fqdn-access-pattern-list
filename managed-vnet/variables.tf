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
