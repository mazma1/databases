// Configure private subnet network routing through nat gatewayresource "google_compute_route" "private_subnet_api" {
 resource "google_compute_route" "private_subnet_route" { 
  name        = "demo-vpc-no-ip-internet-route"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.demo-vpc.self_link}"
  next_hop_instance = "${google_compute_instance.nat_instance.self_link}"
  priority    = 800
  tags = ["private"]
}
