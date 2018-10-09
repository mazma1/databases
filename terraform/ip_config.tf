// Configure external IP addresses
resource "google_compute_address" "nat_ip" {
  name = "nat-instance-ip"
  region = "${var.region}"
}
