// Configure NAT gateways.
resource "google_compute_instance" "ha_proxy" {
  name         = "ha-proxy"
  description  = "An instance to host the HAProxy load balancer"
  machine_type = "${var.machine_type}"
  zone         = "us-central1-a"
  tags = ["public", "http-server"]
  metadata_startup_script = "${var.startup_scripts["haproxy"]}"

  boot_disk {
    initialize_params {
      image = "${var.ha_proxy_image}"
    }
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.public_subnet.self_link}"

    access_config {
      nat_ip = "${google_compute_address.ha_proxy_ip.address}"
    }
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}
