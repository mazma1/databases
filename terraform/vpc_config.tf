resource "google_compute_network" "demo-vpc" {
  name                    = "demo-network"
  description             = "Virtual Private Cloud for demo purpose"
  auto_create_subnetworks = "false"  
}
