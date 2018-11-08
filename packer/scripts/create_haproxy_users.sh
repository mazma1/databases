#!/usr/bin/env bash

### script to create sql users on the master db for load balancing. ###
### users will then be replicated onto the slaves                   ###

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail


set_var() {
  HA_PROXY_PRIVATE_IP=$( gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name=('ha-proxy')" )
}

create_haproxy_users() {
  ###  create two users required by HAProxy for load balancing                         ###
  ### 'haproxy_check' will be used to check the status of a server.                    ###
  ### 'haproxy_root' is needed with root privileges to access the cluster from HAProxy ###
  echo 'About to create user to be used for load balancing....'

  sudo mysql -u "root" -p"${SQL_ROOT_PASSWORD}" -Bse "CREATE USER 'haproxy_check'@'${HA_PROXY_PRIVATE_IP}';
  CREATE USER 'haproxy_root'@'${HA_PROXY_PRIVATE_IP}';
  GRANT ALL PRIVILEGES ON *.* TO 'haproxy_root'@'${HA_PROXY_PRIVATE_IP}'
  flush privileges;"

  echo 'Successfully created HAProxy users'
}


main() {
  set_var
  create_haproxy_users
}

main "$@"
