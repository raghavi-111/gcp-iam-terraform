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

# --- GCP Workforce Access Personas ---

variable "platform_admins" {
  description = "Super admins / emergency incident recovery"
  type        = list(string)
  default     = [
    "mekalaraghavi@gmail.com"
  ]
}

variable "devops_engineers" {
  description = "DevOps / platform delivery engineers"
  type        = list(string)
  default     = []
}

variable "developers" {
  description = "Application & engine developers (VM SSH and dev access)"
  type        = list(string)
  default     = [
    "vanimekala2003@gmail.com"
  ]
}

variable "testers" {
  description = "Testers (Read-only on test VM and data bucket)"
  type        = list(string)
  default     = [
    "urnakam@gmail.com",
    "lakshmiraj@thewify.com",
    "raghavimekala@gmail.com"
  ]
}

variable "security_auditors" {
  description = "Security auditors (Read-only across IAM and logs)"
  type        = list(string)
  default     = []
}

variable "support_users" {
  description = "Support personnel (Monitoring and health check visibility)"
  type        = list(string)
  default     = []
}