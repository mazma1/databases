#!/usr/bin/env bash

# script to install mysql-server on slave's base image

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

export DEBIAN_FRONTEND="noninteractive"
SQL_ROOT_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/sql_root_password -H "Metadata-Flavor: Google")


# update available packages
update_packages() {
  echo 'About to update packages....'

  sudo apt update -y
  sudo apt-get upgrade -y

  sudo apt-get install bc

  echo 'Successfully updated packages.'
}

install_mysql() {
  echo 'About to install MySQL....'

  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${SQL_ROOT_PASSWORD}"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${SQL_ROOT_PASSWORD}"

  sudo apt-get install mysql-server -y

  echo 'Successfully installed MySQL.'
}


main() {
  update_packages
  install_mysql
}

main "$@"
