# bd-dep-splunk-universal-forwarder
This is a splunk universal forwarder service used to forward Forcepoint logs into a splunk indexer

## Package

You need to download splunk universalforwarder linux version into the deploy directory first
splunkforwarder-*.tgz can be found in splunk website
this was tested based on splunkforwarder-8.0.5-a1a6394cc5ae-Linux-x86_64.tgz (can be found in bd-generic.eu-artifactory.cicd.cloud.fpdev.io)

```bash
./build/create-deployment.sh
```

## Implementation

### Traditional 

####	Unpack the deployment package 
```bash
sudo tar -zxvf fp-splunk-universal-forwarder-v1.tar.gz -C /opt/
```

#### Run the commands below:

##### For PA

```bash
export FP_ENABLE_PA_FORWARD=true
```
##### For CSG

```bash
export FP_ENABLE_CSG_FORWARD=true
```
##### For NGFW

```bash
export FP_ENABLE_NGFW_FORWARD=true
```

####	Replace the value parts with the SMC chosen forwarding port, and run the command below:

```bash
export FP_SOURCETYPE_NGFW_MONITOR_VALUE=<smc-forwarding-port>
```

####	Setup the splunk receiving host and port by running the script below, this script will ask you to provide the ip address of the splunk indexer and the reciving port number

```bash
sudo chmod +x /opt/fp-splunk-universal-forwarder/deploy/setup-splunk-config.sh
/opt/fp-splunk-universal-forwarder/deploy/setup-splunk-config.sh
```

####	Run the setup script with one of the commands in the example below to install the program prerequisites and run it.
Note: when you start the forwarder for the first time, it prompts you to enter the splunk-universal forwarder username (admin) and to create an admin password.
 
```bash
/opt/fp-splunk-universal-forwarder/deploy/setup.sh
```

### Docker

```bash
docker build -t fp-splunk-universal-forwarder . 
```

#### Run the container with the following command (FP_SOURCETYPE=private-access):

```bash
docker run --detach \
    --env "SPLUNK_START_ARGS=--accept-license" \
    --env "SPLUNK_PASSWORD=<universal-forwarder-password-of-your-choice>" \
    --env "SPLUNK_INDEXER_IP_ADDRESS=<splunk-indexer-ip-address>" \
    --env "SPLUNK_INDEXER_RECEIVING_PORT=<splunk-indexer-receiving-port>" \
    --env "FP_ENABLE_PA_FORWARD=true" \
    --name fp-pa-splunk-universal-forwarder \
    --restart unless-stopped \
    --volume FpPaLogsVolume:/app/forcepoint-logs:ro \
    fp-splunk-universal-forwarder
```

#### Run the container with the following command (FP_SOURCETYPE=cloud-security-gateway):

```bash
docker run --detach \
    --env "SPLUNK_START_ARGS=--accept-license" \
    --env "SPLUNK_PASSWORD=<universal-forwarder-password-of-your-choice>" \
    --env "SPLUNK_INDEXER_IP_ADDRESS=<splunk-indexer-ip-address>" \
    --env "SPLUNK_INDEXER_RECEIVING_PORT=<splunk-indexer-receiving-port>" \
    --env "FP_ENABLE_CSG_FORWARD=true" \
    --name fp-csg-splunk-universal-forwarder \
    --restart unless-stopped \
    --volume FpCsgLogsVolume:/app/forcepoint-logs:ro \
    docker.frcpnt.com/fp-splunk-universal-forwarder
```

#### Run the container with the following command (FP_SOURCETYPE=next-generation-firewall):

```bash
docker run --detach \
    --env "SPLUNK_START_ARGS=--accept-license" \
    --env "SPLUNK_PASSWORD=<universal-forwarder-password-of-your-choice>" \
    --env "SPLUNK_INDEXER_IP_ADDRESS=<splunk-indexer-ip-address>" \
    --env "SPLUNK_INDEXER_RECEIVING_PORT=<splunk-indexer-receiving-port>" \
    --env "FP_ENABLE_NGFW_FORWARD=true" \
    --env "FP_SOURCETYPE_NGFW_MONITOR_VALUE=<smc-forwarding-port>" \
    --name fp-ngfw-splunk-universal-forwarder \ 
    --publish <smc-forwarding-port>:<smc-forwarding-port> \ 
    --restart unless-stopped \
    docker.frcpnt.com/fp-splunk-universal-forwarder
```

#### Run all

```bash
docker run --detach \
    --env "SPLUNK_START_ARGS=--accept-license" \
    --env "SPLUNK_PASSWORD=<universal-forwarder-password-of-your-choice>" \
    --env "SPLUNK_INDEXER_IP_ADDRESS=<splunk-indexer-ip-address>" \
    --env "SPLUNK_INDEXER_RECEIVING_PORT=<splunk-indexer-receiving-port>" \
    --env "FP_ENABLE_PA_FORWARD=true" \
    --env "FP_ENABLE_CSG_FORWARD=true" \
    --env "FP_ENABLE_NGFW_FORWARD=true" \
    --env "FP_SOURCETYPE_NGFW_MONITOR_VALUE=<smc-forwarding-port>" \
    --name fp-products-splunk-universal-forwarder \ 
    --publish <smc-forwarding-port>:<smc-forwarding-port> \ 
    --restart unless-stopped \
    --volume FpLogsVolume:/app/forcepoint-logs:ro \
    docker.frcpnt.com/fp-splunk-universal-forwarder
```