variable "aws_access_key_id" {
  description = "ssh key name"
  # sensitive   = true
}

variable "aws_secret_access_key" {
  description = "ssh key"
  # sensitive   = true
}

variable "git_server" {
  description = "repo for the flask server"
  default     = "https://github.com/nunocalaim/Setup-Flask-Machine.git"
}
