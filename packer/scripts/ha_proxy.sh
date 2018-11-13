#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server

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
  echo 'About to install and enable HAProxy....'

  sudo apt-get install haproxy -y

  # enable HAProxy...
  echo 'ENABLED=1' | sudo tee -a /etc/default/haproxy;

  echo 'Successfully installed HAProxy.'

  echo 'About to back up existing HAProxy config file...'
  sudo cp /etc/haproxy/haproxy.cfg{,.original}
  echo 'Done backing up existing config file.'

  sudo sed -i "s/.*mode*/# mode http/" /etc/haproxy/haproxy.cfg
  sudo sed -i "s/.*httplog*/# option httplog/" /etc/haproxy/haproxy.cfg
}

turn_selinux_boolean_on() {
  echo 'About to turn on the haproxy_connect_any boolean....'

  ######## Skip post-install configuration step for policycoreutils, just install package ###########
  ######## Was added to fix maintainer's postinstall script failure for policycoreutils: ############
  ######## subprocess installed post-installation script returned error exit status 1 ###############
  ######## Errors were encountered while processing: selinux-policy-default E: Sub-process /usr/bin/dpkg returned an error code (1) #########
  ######## https://serverfault.com/questions/347937/how-do-i-ask-apt-get-to-skip-all-post-install-configuration-steps #######################
  sudo su
  echo exit 101 > /usr/sbin/policy-rc.d
  chmod +x /usr/sbin/policy-rc.d
  apt-get install policycoreutils -y
  rm -f /usr/sbin/policy-rc.d

  # turn on the haproxy_connect_any boolean so haproxy can connect to all TCP ports
  setsebool -P haproxy_connect_any on

  echo 'HAProxy can now connect to all TCP ports. Scipt completed successfully!'
}


main() {
  update_packages
  install_mysql
  install_haproxy
  turn_selinux_boolean_on
}

main "$@"
