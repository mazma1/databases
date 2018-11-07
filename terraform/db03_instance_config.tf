// Configure DB instance3.
resource "google_compute_instance" "db03_instance" {
  name         = "db03"
  machine_type = "${var.machine_type}"
  zone         = "us-central1-c"
  tags         = ["private"]
  boot_disk {
    initialize_params {
      image = "${var.slave2_image}"
    }
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.private_subnet.self_link}"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}
