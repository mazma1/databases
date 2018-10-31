#!/usr/bin/env bash

# script to install mysql-server and configure server as a master

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

export DEBIAN_FRONTEND="noninteractive"

CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
SQL_ROOT_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/sql_root_password -H "Metadata-Flavor: Google")
SLAVE_USERNAME=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/slave_username -H "Metadata-Flavor: Google")
SLAVE_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/slave_password -H "Metadata-Flavor: Google")


# update available packages
update_packages() {
  echo 'About to update packages....'

  sudo apt update -y
  sudo apt-get upgrade -y

  echo 'Successfully updated packages.'
}

install_mysql() {
  echo 'About to install MySQL....'

  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${SQL_ROOT_PASSWORD}"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${SQL_ROOT_PASSWORD}"

  sudo apt-get install mysql-server -y

  echo 'Successfully installed MySQL.'
}

update_config_file() {
  echo 'Updating MySQL config in /etc/mysql/mysql.conf.d/mysqld.cnf....'
  
  #update bind address, server-id and log_bin values with perl find and replace
  sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" $CONFIG_FILE
  sudo sed -i '/server-id/s/^#//g' $CONFIG_FILE
  sudo sed -i '/log_bin/s/^#//g' $CONFIG_FILE

  sudo service mysql restart

  echo 'Successfully updated MySQL config file'
}

create_replication_user() {
  echo 'About to create user to be used for replication....'

  sudo mysql -u "root" -p"${SQL_ROOT_PASSWORD}" -Bse "CREATE USER '${SLAVE_USERNAME}'@'%' identified by '${SLAVE_PASSWORD}';
  GRANT REPLICATION slave ON *.* TO '${SLAVE_USERNAME}'@'%';"

  echo 'Successfully created replication user'
}

create_test_data() {
  echo 'About to create data for testing replication....'

  sudo mysql -u "root" -p"${SQL_ROOT_PASSWORD}" -Bse "CREATE DATABASE pets;
  CREATE TABLE pets.dogs (name varchar(20));
  INSERT INTO pets.dogs values ('fluffy');"

  echo 'Successfully created replication test data'
}

main() {
  update_packages
  install_mysql
  update_config_file
  create_replication_user
  create_test_data
}

main "$@"
