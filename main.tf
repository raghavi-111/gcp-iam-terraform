terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Cloud Storage Bucket (Tester can view, cannot delete/write)
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
    access_config {} # Public IP
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Build / Startup script to serve your application
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx git
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>App Deployed Successfully on flash-cache-508914-u3</h1>" > /var/www/html/index.html
  EOF

  tags = ["http-server"]
}

# Allow HTTP Traffic to VM
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

# ----------------- 3. IAM ROLES PROVISIONING -----------------

# Raghavi -> Super Admin (Owner of the GCP project)
resource "google_project_iam_member" "super_admin_raghavi" {
  project = var.project_id
  role    = "roles/owner"
  member  = "user:${var.raghavi_email}"
}

# Developer (Vani) -> Access to VM to check files, edit, and manage compute
resource "google_project_iam_member" "dev_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "user:${var.vani_email}"
}

resource "google_project_iam_member" "dev_oslogin" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "user:${var.vani_email}"
}

# Tester -> Read-only Viewer on VM and Bucket
resource "google_project_iam_member" "tester_vm_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "user:${var.tester_email}"
}

resource "google_storage_bucket_iam_member" "tester_bucket_viewer" {
  bucket = google_storage_bucket.app_bucket.name
  role   = "roles/storage.objectViewer"
  member = "user:${var.tester_email}"
}