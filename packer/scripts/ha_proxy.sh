#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server's base image

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

export DEBIAN_FRONTEND="noninteractive"

HAPROXY_SQL_ROOT_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/haproxy_sql_root_password -H "Metadata-Flavor: Google")

# update available packages
update_packages() {
  echo 'About to update packages....'

  sudo apt update -y
  sudo apt-get upgrade -y

  echo 'Successfully updated packages.'
}

install_mysql() {
  echo 'About to install MySQL....'

  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${HAPROXY_SQL_ROOT_PASSWORD}"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${HAPROXY_SQL_ROOT_PASSWORD}"

  sudo apt-get install mysql-server -y

  echo 'Successfully installed MySQL.'
}

install_haproxy() {
  echo 'About to install HAProxy....'
  sudo apt install policycoreutils -y
  sudo apt-get install haproxy -y
  echo 'Successfully installed HAProxy.'

  echo 'About to back up existing HAProxy config file...'
  sudo cp /etc/haproxy/haproxy.cfg{,.original}
  echo 'Done backing up existing config file.'

  sudo sed -i "s/.*modei*/# mode http/" /etc/haproxy/haproxy.cfg
  sudo sed -i "s/.*httplog*/# option httplog/" /etc/haproxy/haproxy.cfg
}


main() {
  update_packages
  install_mysql
  install_haproxy
}

main "$@"
