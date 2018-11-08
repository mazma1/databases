# Databases and Load Balancing
This is a demonstration of how the setup of a load balanced database cluster with one master and two slaves can be automated using Packer, Terraform and bash scripts. In this example, we will configure one HAProxy server to load balance traffic to the three back-end MySQL servers. We will configure a total of two MySQL users for HAProxy, one to perform a health check and verify services and another to access MySQL for data retrieval. Please follow the instructions carefully to get the desired result.

## Technology Stack
---
- Google Cloud Platform
- MySQL
- Packer
- Terraform
- HAProxy
- Bash


## Get Started - Prerequisites
---
Before you can test out the scripts, the following must have been taken care of:
1. You should have an account on Google Cloud Platform. You can visit [here](https://cloud.google.com/) to sign up if you don't.

2. Create a [project](https://medium.com/google-cloud/how-to-create-cloud-platform-projects-using-the-google-cloud-platform-console-e6f2cb95b467) from your GCP console for the test purpose.

3. Create a service account key from the Google Cloud console and download in `json` format. You can find a guide in the **Setting Up Authentication** section of this [post](https://medium.com/@naz_islam/how-to-authenticate-google-cloud-services-on-heroku-for-node-js-app-dda9f4eda798).

    After downloading the key, place it in the root of the repository and rename the file to `gcp_account.json`.

4. Add the following parameters as project-wide [metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata#projectwide) (similar to environment variables). These variables will be used in the configuration process. Follow the same pattern shown in the [sample file](metadata.sample), but feel free to update the values to what ever you choose.
5. Install [Packer](https://www.packer.io/intro/getting-started/install.html) and [Terraform](https://www.terraform.io/intro/getting-started/install.html) if you do not already have them installed on your local machine.

## Network Design
This project was designed to be hosted in a Public and Privately Routed VPC on Google Cloud. The details of the considerations made while designing this are contained in this [document](https://docs.google.com/document/d/1iBSyzm12Rixvs1rQeRclkkI44Woa1xW1OhcsK8a92A8/edit?usp=sharing).

## Create the Base Images
---
This step will create the base images that will be used to build the master, slave and HAProxy servers. These images will be preconfigured with setups for these purposes respectively.

1. Clone the repository and navigate to the project folder in your terminal.
2. Change directory to the `packer` directory:

    `cd packer`

3. Provide your project id as an environment variable:

    ![project id](img/project_id.png?raw=true "project id")

    `export PROJECT_ID=<your-project-id>`

4. Validate that the packer template files for these images are correct. The command should return a message indicating successful validation respectively:
    ```
    packer validate ./templates/master.json

    packer validate ./templates/slave1.json

    packer validate ./templates/slave2.json

    packer validate ./templates/ha_proxy.json
    ```

5.  Build the packer images for the master, slave and HAProxy servers with the following commands respectively:
    ```
    packer build ./templates/master.json

    packer build ./templates/slave1.json

    packer build ./templates/slave2.json

    packer build ./templates/ha_proxy.json
    ```

    You will find your custom images in the registry once they are successfully created:

    ![custom images](img/images.png?raw=true "custom images")

## Build the Infrastructure
With the base images in place, we can now proceed to spin up our servers with them.

1. Move out from the `packer` directory into `terraform`:

    `cd ../terraform`

2. Initialize Terraform and download necessary modules:
       
      `terraform init`

3. View a plan of the resources that will be added to your infrastructure:

    `terraform plan`

4. Run `terraform apply` to set up the infrastructure, and follow the prompts to provide required confirmation.

Once the `apply` step is done, the required resources would have been added to your project. Take note of the following instances (servers) that were created:
  
  - **db01**: Master database server
  - **db02 & db03**: Slave database servers
  - **ha-proxy**: HAProxy loadbalancer server
  - **nat-instance**: The NAT gateway instance from which you can access the master and slave servers.

  The following configurations has been done for the master server (via the custom base image):

  - Installed MySQL and updated its configuration to make the server a master.
  - Created a replication user
  - Created a test database `pets`, with a `dogs` table
 
 However, the slave servers only come with MySQL installed out of the box. The remaining setup will be done in the steps below.

 ## Complete Replication Setup
 1. Log in to the `nat-instance` server by using the `SSH` link as shown in the screenshot below:

    ![ssh access](img/ssh.png?raw=true "ssh access")

2. Once in the `nat-instance`, log in to the master server as `packer` user:
    ```
    gcloud beta compute ssh db01 --internal-ip --zone us-central1-a

    sudo su - packer
    ```

3. Using a different browser window, log in to one slave server, say db02 as `packer` user as well:
    ```
    gcloud beta compute ssh db02 --internal-ip --zone us-central1-b

    sudo su - packer
    ```
    ![master slave ssh](img/master_slave_ssh.png?raw=true "master slave ssh")

4. From **master**, execute `create_haproxy_users.sh`: to configure the users required for load balancing:
    ```
    sudo chmod +x ./create_haproxy_users.sh

    ./create_haproxy_users.sh
    ```
    You will prompted for your SQL password when executing the scipt. Ensure to enter the correct `sql_root_password` value as specified in the metadata.

5. From **master**, take a dump of the database using `mysqldump`:
    ```
    sudo mysqldump -uroot -p<your-sql-root-password> --all-databases --master-data > masterdump.sql
    ```

    Note that `<your-sql-root-password>` should match what you added to the metadata.

    After taking the dump, run `ls` to confirm that the dump file `masterdump.sql` exists. 

6. From **master**, create an `ssh` key that will be added to the slave servers for `ssh` authentication:
    ```
    ssh-keygen -t rsa
    ```
    Just press `enter` when prompted to enter a file and passphrase for your key pair.

    Once the key pair has been created, display the content of your `id_rsa.pub` key and copy the output for the next step:
    ```
    cat ~/.ssh/id_rsa.pub
    ```

7. From **slave**, add the public key from **6.** to the `authorized_keys` file:
    ```
    echo public_key_string >> ~/.ssh/authorized_keys
    ```

      Substitute the `public_key_string` with the output from the `cat ~/.ssh/id_rsa.pub` command you must have copied.

8. From **master**, copy the dump file to the slave:
    ```
    scp -i ./.ssh/id_rsa masterdump.sql packer@<internal-ip-of-db02>:~/masterdump.sql
    ```

    Substitute `<internal-ip-of-db02>` with the internal IP of db02. After the copy step, confirm that the file now exists on the slave with an `ls` command.

9. From **slave**: now we have a copy of the dump file on the slave, execute a script to finish up the slave replication setup:
    ```
    sudo chmod +x ./slave_replication.sh

    ./slave_replication.sh
    ```

    If you get an output **Slave IO state OK** at the end of the script execution, then that means that your slave replication was set up correctly.


With the first slave server sorted out, you should set up the second slave server (**db03**) as well. `SSH` into **db03** through the NAT gateway instance and repeat steps **7.** to **9.**.

You don't need to generate a new `ssh` key pair for the master, just work with the one created in step **6.**

Also when running the command to copy the dump file to the slave, be sure to update the destination IP address to match that of **db03**, ie:
  ```
  scp -i ./.ssh/id_rsa masterdump.sql packer@<internal-ip-of-db03>:~/masterdump.sql
  ```

## Testing that Replication Works
  1. From **master**, login to mysql:
      ```
      sudo mysql -uroot -p<your-sql-root-password>
      ```

  2. Once in MySQL prompt, add a new entry to the `dogs` table in the database:
      ```
      INSERT INTO pets.dogs values ('bingo');"
      ```
    
  3. Confirm that the entry was added successfully:
      ```
      SELECT * from pets.dogs;
      ```
        You should see `fluffy` and `bingo` in the result output.

  4. From any **slave**, login to mysql:
      ```
      sudo mysql -uroot -p<your-sql-root-password>
      ```

  5. Retrieve the contents of the `dogs` table:
      ```
      SELECT * from pets.dogs;
      ```
        Voila! You should see `fluffy` and `bingo` in the result as well. You can repeat steps **4.** and **5.** for the second slave instance and hopefully, the result will be the same.


## Load Balancing
At this point, the database cluster should be up, with replication correctly set up. What's left is to update the configuration of the load balancer to begin to listen for requests, and distribute traffic to the servers based on algorithm specified in the config.  The following configurations has been done for the HAProxy server (via the custom base image):

- MySQL installed
- HAProxy installed and enabled. Executing `sudo service haproxy status` should show that it is active.
- A backup of the existing configuration file taken:

    - Working copy: `/etc/haproxy/haproxy.cfg` 
    - Backup file: `/etc/haproxy/haproxy.cfg.original` 

    If you ever need to restore the original config file, always comment out line `23` and `24`. This was done programatically in the base image:

    ![haproxy config working copy](img/haproxy_config_working_copy.png?raw=true "haproxy config working copy")
    

### Complete the Load Balancing Setup
1. `SSH` into HAProxy's server. This is a public facing instance with a public IP so you can connect directly using the SSH shortcut on the VM instances page (on Google Cloud)

2. Log in to the home directory of the root user:
    ```
    sudo su

    cd ~
    ```

3. Open the working copy of the config file and add the following blocks of configuration:

    ```
    listen mysql-cluster
        bind <haproxy-internal-ip>:3306
        mode tcp
        option mysql-check user haproxy_check
        balance roundrobin
        server db01 <db01-internal-ip>:3306 check
        server db02 <db02-internal-ip>:3306 check
        server db03 <db03-internal-ip>:3306 check
    ```

    Substitute `<haproxy-internal-ip>`, `<db01-internal-ip>`, `<db02-internal-ip>` and `<db03-internal-ip>` with the respective internal IPs of these servers:

    ![mysql cluster block](img/mysql-cluster-config.png?raw=true "mysql cluster")

    - Line `41` specifies the user (already created in the base image) that will perform a check to ascertail if the MySQL servers are are up or not (via `mysql-cluster` configuration)
    - Line `42` specifies the load balancing algorithm to be used. Round Robin works by selecting servers sequentially from the cluster. The load balancer will select the first server on its list for the first request, then move down the list in order, starting over at the top when it reaches the end.


    ```
    listen stats
       bind *:8080
       mode http
       option httplog
       stats enable
       stats uri /
       stats realm Strictly\ Private
       stats auth username:password
    ``` 
    
    This config block enables HAProxy's web UI so we can see the statistics of load balancing. `username` and `password` in `stats auth` will be used to log in to the web UI, so you can update it to wahtever values you wish.

    Your config file now look like this after adding these blocks:

    ![updated config](img/updated_config.png?raw=true "updated config")


4. Once the updated configuration has been saved, reload HAProxy and check the status to ensure that it reloaded correctly with no error:
    ```
    service haproxy reload

    service haproxy status

    :q  # COMMENT: to exit the status page 
    ```
    ![cluster started](img/mysql_cluster_started.png?raw=true "cluster started")

    The prompts **Proxy mysql-cluster started.** and **Proxy stats started.** from the status output indicate that the load balancing configuration was applied successfully.

5. Access the web UI:
    ```
    http://<Public IP of Load Balancer>:8080/
    ```
    If everything goes well, you will have your database servers up (indicated by the green color code) on the dashboard like so:

    ![web ui](img/web_ui.png?raw=true "web ui")

6. If everything still looks good at this point, then it's time to test that the load balancing *actually* works:
    ```
    for i in `seq 1 6`; do mysql -h 0.0.0.0 -uhaproxy_root -e "show variables like 'server_id'"; done
    ```

    Substitute `0.0.0.0` with the private IP of the load balancer (same as that specified on line `39` of the screenshot in **3.**

    The output of the above command sholud look like this:

    ![lb test result](img/result.png?raw=true "lb test result")

    The command queries the cluster six times for a server's `server_id` and the result demonstrates **round robin** load balancing where the servers are picked sequentially to fulfil the request. The first reqquest goes to `db01` which has a `server_id` of 1 (as the master). The next request goes to `db02` with a `server_id` of 2, and the the next request goes to `db03` with a `server_id` of 3. With the list of servers exhausted, the subsequent request go round again starting from the first server on the list.



