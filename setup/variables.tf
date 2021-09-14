variable "region1" {
    type        = string
    description = "Default region for GCP resources"
    default     = "us-central1"
}

variable "zone1" {
    type        = string
    description = "Default zone for GCP resources"
    default     = "us-central1-f"
}

variable "region2" {
    type        = string
    description = "Default region for GCP resources"
    default     = "europe-west1"
}

variable "zone2" {
    type        = string
    description = "Default zone for GCP resources"
    default     = "europe-west1-c"
}

variable "region3" {
    type        = string
    description = "Default region for GCP resources"
    default     = "asia-south1"
}

variable "zone3" {
    type        = string
    description = "Default zone for GCP resources"
    default     = "asia-south1-a"
}


variable "project" {
    type        = string
    description = "The project in which to place all new resources"
}
