// Configure DB instance2.
resource "google_compute_instance" "db02_instance" {
  name         = "db02"
  machine_type = "${var.machine_type}"
  zone         = "us-central1-b"
  tags         = ["private"]
  boot_disk {
    initialize_params {
      image = "${var.slave1_image}"
    }
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.private_subnet.self_link}"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}
