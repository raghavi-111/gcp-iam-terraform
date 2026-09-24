variable "project_id" {
  type    = string
  default = "flash-cache-508914-u3"
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "zone" {
  type    = string
  default = "asia-south1-a"
}

variable "raghavi_email" {
  type        = string
  description = "Super admin email"
  default     = "mekalaraghavi@gmail.com"
}

variable "vani_email" {
  type        = string
  description = "Developer email"
  default     = "vanimekala2003@gmail.com"
}

variable "tester_email" {
  type        = string
  description = "Tester email"
  default     = "lakshmiraj@thewify.com"
}