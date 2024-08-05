variable "server_message" {
  type        = string
  description = "Message displayed on server."
  # default = "Hello!"
}

variable "sg_name_allow_http" {
  type    = string
  default = "allow-http"
}