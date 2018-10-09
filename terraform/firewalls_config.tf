// Setup project firewalls
resource "google_compute_firewall" "allow_public_ssh_icmp" {
  name          = "public-ssh-icmp"
  description   = "Allow SSH access into the public subnet of the Virtual Private Cloud."
  network       = "${google_compute_network.demo-vpc.self_link}"
  allow {
    protocol    = "tcp"
    ports       = ["22"]
  }

  allow {
    protocol    = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public"]
}

resource "google_compute_firewall" "allow_private_ssh_icmp" {
  name          = "private-ssh-icmp"
  description   = "Allow SSH access into the private subnet of the Virtual Private Cloud."
  network       = "${google_compute_network.demo-vpc.self_link}"
  allow {
    protocol    = "tcp"
    ports       = ["22"]
  }

  allow {
    protocol    = "icmp"
  }
  source_tags = ["public", "private"]
  target_tags   = ["private"]
}
