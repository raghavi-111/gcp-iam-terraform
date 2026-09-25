terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "flash-cache-508914-u3-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Cloud Storage Bucket
resource "google_storage_bucket" "app_bucket" {
  name                        = "${var.project_id}-task-bucket"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# 2. Virtual Machine (Compute Engine)
resource "google_compute_instance" "app_vm" {
  name         = "app-workload-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx git
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Black River App - Environment Online</h1>" > /var/www/html/index.html
  EOF

  tags = ["http-server"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-service"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# ==============================================================================

# ==============================================================================

# --- Platform Administrators (Full Owner privileges) ---
resource "google_project_iam_member" "platform_admins" {
  for_each = toset(var.platform_admins)
  project  = var.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

# --- Developers (VM Instance Admin + OS Login) ---
resource "google_project_iam_member" "dev_compute_admin" {
  for_each = toset(var.developers)
  project  = var.project_id
  role     = "roles/compute.instanceAdmin.v1"
  member   = "user:${each.value}"
}

resource "google_project_iam_member" "dev_oslogin" {
  for_each = toset(var.developers)
  project  = var.project_id
  role     = "roles/compute.osAdminLogin"
  member   = "user:${each.value}"
}

# --- Testers (Compute Viewer + Bucket Object Viewer) ---
resource "google_project_iam_member" "tester_vm_viewer" {
  for_each = toset(var.testers)
  project  = var.project_id
  role     = "roles/compute.viewer"
  member   = "user:${each.value}"
}

resource "google_storage_bucket_iam_member" "tester_bucket_viewer" {
  for_each = toset(var.testers)
  bucket   = google_storage_bucket.app_bucket.name
  role     = "roles/storage.objectViewer"
  member   = "user:${each.value}"
}

# --- Security Auditors (Read-only on IAM, Logs, and Configs) ---
resource "google_project_iam_member" "security_auditors" {
  for_each = toset(var.security_auditors)
  project  = var.project_id
  role     = "roles/iam.securityReviewer"
  member   = "user:${each.value}"
}

# --- Support Users (Dashboard and Monitoring Viewers) ---
resource "google_project_iam_member" "support_monitoring" {
  for_each = toset(var.support_users)
  project  = var.project_id
  role     = "roles/monitoring.viewer"
  member   = "user:${each.value}"
}


# ==============================================================================
# DevOps Engineers (Create VMs, Manage Servers, Trigger Cloud Build)
# ==============================================================================

# 1. Full VM instance lifecycle (Create, start, stop, delete, modify VMs)
resource "google_project_iam_member" "devops_compute_admin" {
  for_each = toset(var.devops_engineers)
  project  = var.project_id
  role     = "roles/compute.instanceAdmin.v1"
  member   = "user:${each.value}"
}

# 2. Service Account User (Mandatory to attach service accounts when creating new VMs)
resource "google_project_iam_member" "devops_sa_user" {
  for_each = toset(var.devops_engineers)
  project  = var.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = "user:${each.value}"
}

# 3. Cloud Build Editor (Create, run, and review builds)
resource "google_project_iam_member" "devops_cloud_build" {
  for_each = toset(var.devops_engineers)
  project  = var.project_id
  role     = "roles/cloudbuild.builds.editor"
  member   = "user:${each.value}"
}