// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("../gcp_account.json")}"
  project     = "d1-d2-218406"
  region      = "${var.region}"
  version     = "~> 1.19"
}
