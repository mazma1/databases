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

  SERVER_ID=$( echo $RANDOM % 10 + 2 | bc )

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

main() {
  set_vars
  update_config_file
  setup_slave_replication
}

main "$@"
