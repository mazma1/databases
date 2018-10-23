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

resource "google_compute_firewall" "allow_internal" {
  name          = "allow-internal"
  description   = "Allow internal traffic on the network."
  network       = "${google_compute_network.demo-vpc.self_link}"
  allow {
    protocol    = "tcp"
    ports       = ["0-65535"]
  }

  allow {
    protocol    = "udp"
    ports       = ["0-65535"]
  }

  allow {
    protocol    = "icmp"
  }
  source_tags = ["public", "private"]
  target_tags   = ["private", "public"]
}

resource "google_compute_firewall" "allow_all_outbound" {
  name               = "allow-all-outbound"
  description        = "Allow all outbound connections access across the firewall of the Virtual Private Cloud."
  direction          = "EGRESS"
  network            = "${google_compute_network.demo-vpc.self_link}"
  allow {
    protocol    = "tcp"
    ports       = ["80", "8080", "443"]
  }
  destination_ranges = ["0.0.0.0/0"]
}
