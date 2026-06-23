variable "function_name" {}
variable "handler" {}
variable "runtime" {}
variable "role_arn" {}
variable "source_dir" {}

variable "environment_vars" {
  type    = map(string)
  default = {}
}