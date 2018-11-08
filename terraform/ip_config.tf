// Configure external IP addresses
resource "google_compute_address" "nat_ip" {
  name = "nat-instance-ip"
  region = "${var.region}"
}

resource "google_compute_address" "ha_proxy_ip" {
  name = "ha-proxy-instance-ip"
  region = "${var.region}"
}
