// Configure DB instance1.
resource "google_compute_instance" "db01_instance" {
  name         = "db01"
  machine_type = "${var.machine_type}"
  zone         = "us-central1-a"
  tags         = ["private"]
  boot_disk {
    initialize_params {
      image = "${var.master_image}"
    }
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.private_subnet.self_link}"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}
