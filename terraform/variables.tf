variable "image" {
  default = "ubuntu-1604-xenial-v20181004"
}

variable "master_image" {
  default = "master"
}

variable "slave1_image" {
  default = "slave-one"
}

variable "slave2_image" {
  default = "slave-two"
}

variable "ha_proxy_image" {
  default = "ha-proxy"
}

variable "machine_type" {
  default = "f1-micro"
}

variable "region" {
  default = "us-central1"
}

variable "subnet_cidrs" {
  type = "map"
  default = {
    private = "10.0.2.0/24"
    public = "10.0.1.0/24"
  }
}

variable startup_scripts {
  type = "map"
  default = {
    nat = "sudo sysctl -w net.ipv4.ip_forward=1; sudo iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE"
    haproxy = "echo 'net.ipv4.ip_nonlocal_bind=1' | sudo tee -a /etc/sysctl.conf; echo 'ENABLED=1' | sudo tee -a /etc/default/haproxy; sudo setsebool haproxy_connect_any on"
  }
}