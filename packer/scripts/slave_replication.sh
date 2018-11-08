#!/usr/bin/env bash

# script to set up replication on the slave servers

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

set_vars() {
  SLAVE_NAME=$( curl http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google" )
  SQL_ROOT_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/sql_root_password -H "Metadata-Flavor: Google")
  SLAVE_USERNAME=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/slave_username -H "Metadata-Flavor: Google")
  SLAVE_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/slave_password -H "Metadata-Flavor: Google")
  INSTANCE_IP=$( gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=($SLAVE_NAME)" )
  MASTER_HOST=$( gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=('db01')" )
}

update_config_file() {
  echo "Updating MySQL config in $CONFIG_FILE...."

  if [ $SLAVE_NAME = "db02" ]; then
		SERVER_ID=2
	else
		SERVER_ID=3
	fi

  echo $SERVER_ID
  
  #update bind address and server-id values
  sudo sed -i "s/.*bind-address.*/bind-address = $INSTANCE_IP/" $CONFIG_FILE
  sudo sed -i "s/.*#server-id.*/server-id = $SERVER_ID/" $CONFIG_FILE

  sudo service mysql restart

  echo 'Successfully updated MySQL config file'
}

setup_slave_replication() {
  echo "Setting up slave replication"

  sudo mysql -uroot  -p"${SQL_ROOT_PASSWORD}" -Bse "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}',
  MASTER_USER='${SLAVE_USERNAME}',
  MASTER_PASSWORD='${SLAVE_PASSWORD}';"

  echo 'Successfully set up slave replication'
}

restore_data_from_master_dump() {
  echo "About to restore data from dump..."

  sudo mysql -uroot -p"${SQL_ROOT_PASSWORD}" < masterdump.sql

  echo "Successfully restored data from dump"
}

start_slave() {
  echo 'About to start slave...'

  sudo mysql -uroot  -p"${SQL_ROOT_PASSWORD}" -Bse "start slave;"

  echo 'Successfully started slave'
}

### refresh users' privileges in the slave servers so that the priveleges of ###
### the HAProxy users replicated onto the slaves can be effected.            ###
refresh_users_priveleges() {
  echo 'About to refresh privileges for HAProxy users...'

  sudo mysql -u "root" -p"${SQL_ROOT_PASSWORD}" -Bse "flush privileges;"

  echo 'Done refreshing privileges for HAProxy users.'
}

check_replication_status() {
  echo 'About to check replication status...'

  # Wait for slave to get started and have the correct status
	sleep 2

	# Check if replication status is OK
	SLAVE_OK=$(sudo mysql -uroot -p"${SQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G;" | grep 'Waiting for master')
	if [ -z "$SLAVE_OK" ]; then
		echo "ERROR! Wrong slave IO state."
	else
		echo "Slave IO state OK"
	fi

  echo 'Completed check for replication status'
}

main() {
  set_vars
  update_config_file
  setup_slave_replication
  restore_data_from_master_dump
  start_slave
  refresh_users_priveleges
  check_replication_status
}

main "$@"
