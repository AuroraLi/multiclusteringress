
provider "google" {
    project = var.project
  # Configuration options
}
provider "google-beta" {
    project = var.project
  # Configuration options
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_compute_network" "default" {
  name = "default"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  project = var.project
}

resource "google_compute_subnetwork" "us-subnet" {
  name          = "us-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.default.id
  secondary_ip_range {
    range_name    = "range-1"
    ip_cidr_range = "192.168.0.0/18"
  }
  secondary_ip_range {
    range_name    = "range-2"
    ip_cidr_range = "192.168.128.0/20"
  }
}

resource "google_compute_subnetwork" "eu-subnet" {
  name          = "eu-subnet"
  ip_cidr_range = "10.3.0.0/16"
  region        = "europe-west1"
  network       = google_compute_network.default.id
  secondary_ip_range {
    range_name    = "range-1"
    ip_cidr_range = "192.168.64.0/18"
  }
  secondary_ip_range {
    range_name    = "range-2"
    ip_cidr_range = "192.168.144.0/20"
  }
}

resource "google_compute_subnetwork" "asia-subnet" {
  name          = "asia-subnet"
  ip_cidr_range = "10.4.0.0/16"
  region        = "asia-south1"
  network       = google_compute_network.default.id
  secondary_ip_range {
    range_name    = "range-1"
    ip_cidr_range = "192.168.192.0/18"
  }
  secondary_ip_range {
    range_name    = "range-2"
    ip_cidr_range = "192.168.160.0/20"
  }
}
# IAM permissions for cloudbuild to use K8s
# resource "google_project_iam_member" "cloud_build_GKE_iam" {
#   project = data.google_project.project.number
#   role    = "roles/container.developer"
#   member  = join("",["serviceAccount:",data.google_project.project.number,"@cloudbuild.gserviceaccount.com"])
# }

# The GKE cluster on which to run the websockets code
resource "google_container_cluster" "us_cluster" {
  project = var.project
  provider           = google-beta
  name               = "us-cluster"
  location           = var.zone1
  remove_default_node_pool = true
  initial_node_count       = 1
  network            = google_compute_network.default.name
  subnetwork         = google_compute_subnetwork.us-subnet.name
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }

  }
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.168.0.0/28"
  }
#  master_authorized_networks_config {
#    cidr_blocks {
#        cidr_block = "142.112.223.237/32"
#        display_name = "mac"
#      }
#  }
  ip_allocation_policy {
    cluster_secondary_range_name = "range-1"
    services_secondary_range_name = "range-2"
  }
  enable_shielded_nodes = true
}

resource "google_container_cluster" "eu_cluster" {
  project = var.project
  provider           = google-beta
  name               = "eu-cluster"
  location           = var.zone2
  remove_default_node_pool = true
  initial_node_count       = 1
  network            = google_compute_network.default.name
  subnetwork         = google_compute_subnetwork.eu-subnet.name
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }

  }
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.168.0.32/28"
  }
#  master_authorized_networks_config {
#    cidr_blocks {
#        cidr_block = "142.112.223.237/32"
#        display_name = "mac"
#      }
#  }
  ip_allocation_policy {
    cluster_secondary_range_name = "range-1"
    services_secondary_range_name = "range-2"
  }
  enable_shielded_nodes = true
}



resource "google_container_cluster" "asia_cluster" {
  project = var.project
  provider           = google-beta
  name               = "asia-cluster"
  location           = var.zone3
  remove_default_node_pool = true
  initial_node_count       = 1
  network            = google_compute_network.default.name
  subnetwork         = google_compute_subnetwork.asia-subnet.name
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }

  }
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.168.0.64/28"
  }
#  master_authorized_networks_config {
#    cidr_blocks {
#        cidr_block = "142.112.223.237/32"
#        display_name = "mac"
#      }
#  }
  ip_allocation_policy {
    cluster_secondary_range_name = "range-1"
    services_secondary_range_name = "range-2"
  }
  enable_shielded_nodes = true
}




resource "google_container_node_pool" "us_pool" {
  provider = google-beta
  project    = var.project
  name       = "us-pool"
  location   = var.zone1
  cluster    = google_container_cluster.us_cluster.name
  node_count = 2 

  management {
    auto_repair = "true"
    auto_upgrade = "true"
  }

  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    machine_type = "e2-standard-2"  
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }


  }
}


resource "google_container_node_pool" "eu_pool" {
  provider = google-beta
  project    = var.project
  name       = "eu-pool"
  location   = var.zone2
  cluster    = google_container_cluster.eu_cluster.name
  node_count = 2 

  management {
    auto_repair = "true"
    auto_upgrade = "true"
  }

  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    machine_type = "e2-standard-2"  
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }


  }
}



resource "google_container_node_pool" "asia_pool" {
  provider = google-beta
  project    = var.project
  name       = "asia-pool"
  location   = var.zone3
  cluster    = google_container_cluster.asia_cluster.name
  node_count = 2 

  management {
    auto_repair = "true"
    auto_upgrade = "true"
  }

  node_config {
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    machine_type = "e2-standard-2"  
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }


  }
}



# Workload Identity IAM binding for us in default namespace.
resource "google_service_account_iam_member" "us-sa-workload-identity" {
  service_account_id = google_service_account.us.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/us]"
  depends_on = [
    google_container_cluster.us_cluster
  ]
}

# Workload Identity IAM binding for us in default namespace.
resource "google_service_account_iam_member" "eu-sa-workload-identity" {
  service_account_id = google_service_account.eu.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/eu]"
  depends_on = [
    google_container_cluster.eu_cluster
  ]
}

# Workload Identity IAM binding for us in default namespace.
resource "google_service_account_iam_member" "asia-sa-workload-identity" {
  service_account_id = google_service_account.asia.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/asia]"
  depends_on = [
    google_container_cluster.asia_cluster
  ]
}


# #Role for Pub/Sub
# resource "google_project_iam_member" "pub-sub-role" {
#   project            = var.project
#   role               = "roles/pubsub.editor"
#   member             = "serviceAccount:${google_service_account.us.email}"
# }

# Service account used by us
resource "google_service_account" "us" {
  project      = var.project
  account_id   = "ussagke"
  display_name = "us-sa"
}

# Service account used by eu
resource "google_service_account" "eu" {
  project      = var.project
  account_id   = "eusagke"
  display_name = "eu-sa"
}

# Service account used by eu
resource "google_service_account" "asia" {
  project      = var.project
  account_id   = "asiasagke"
  display_name = "asia-sa"
}
# data "google_compute_network" "net" {
#   name = "default"
#   project = var.project
# }

# data "google_compute_subnetwork" "subnet" {
#   name   = "default"
#   project = var.project
#   region = "us-central1"
# }

resource "google_compute_router" "router-us" {
  name    = "my-router-us"
  project = var.project
  region  = google_compute_subnetwork.us-subnet.region
  network = google_compute_network.default.name

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat-us" {
  name                               = "my-router-nat-us"
  router                             = google_compute_router.router-us.name
  region                             = google_compute_router.router-us.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project = var.project
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_router" "router-eu" {
  name    = "my-router-eu"
  project = var.project
  region  = google_compute_subnetwork.eu-subnet.region
  network = google_compute_network.default.name

  bgp {
    asn = 64515
  }
}

resource "google_compute_router_nat" "nat-eu" {
  name                               = "my-router-nat-eu"
  router                             = google_compute_router.router-eu.name
  region                             = google_compute_router.router-eu.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project = var.project
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}



resource "google_compute_router" "router-asia" {
  name    = "my-router-asia"
  project = var.project
  region  = google_compute_subnetwork.asia-subnet.region
  network = google_compute_network.default.name

  bgp {
    asn = 64516
  }
}

resource "google_compute_router_nat" "nat-asia" {
  name                               = "my-router-nat-asia"
  router                             = google_compute_router.router-asia.name
  region                             = google_compute_router.router-asia.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project = var.project
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}



# resource "google_gke_hub_membership" "us-membership" {
#   membership_id = "gke-us"
#   endpoint {
#     gke_cluster {
#       resource_link = "//container.googleapis.com/${google_container_cluster.us_cluster.id}"
#     }
#   }
#   authority {
#     issuer = "https://container.googleapis.com/v1/${google_container_cluster.us_cluster.id}"
#   }
# }


# resource "google_gke_hub_membership" "eu-membership" {
#   membership_id = "gke-eu"
#   endpoint {
#     gke_cluster {
#       resource_link = "//container.googleapis.com/${google_container_cluster.eu_cluster.id}"
#     }
#   }
#   authority {
#     issuer = "https://container.googleapis.com/v1/${google_container_cluster.eu_cluster.id}"
#   }
# }