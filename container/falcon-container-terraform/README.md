# Terraform to demo Falcon Container Runtime Protection

This terraform demo...
 * Creates a single AKS cluster
 * Creates a single Azure VM instance to manage the cluster
 * Creates a Azure Container Registry (ACR)
 * Enables Azure Key Vault
 * Stores Falcon Credentials in the key vault
 * Downloads the Falcon Container Sensor
 * Pushes the Falcon Container Sensor to ACR
 * Deploys the Falcon Container Sensor to the AKS Cluster
 * Deploys the vulnerable.example.com application to AKS

User then may
 * Show that container workload (vulnerable.example.com) appears in Falcon Console (under Hosts, or Containers Dashboard)
 * Visit vulnerable.example.com application and exploit it through the web interface
 * Show detections in Falcon Console

### Prerequsites
 - Authenticated access to Azure
 - Have Containers enabled in Falcon console (CWP subscription)
 - Falcon CID and API key and secret with Sensor Download

### Usage

 - Open your Azure cloud shell
 - Verify that your are on the correct subscription
 - Verify that your identity in upper right corner is correct)
 - Paste the following to your cloud shell
 
```
wget https://raw.githubusercontent.com/mccbryan3/Cloud-Azure/falcon-container-terraform/container/falcon-container-terraform/demo
```
```
/bin/bash demo up
```

NOTE:

* This demo will prompt for the required API Client ID, Secret and CID for your falcon platform.
* This demo will also prompt on whether to install the LUMOS (falcon-container) sensor
    * If you choose not to install LUMOS the Kernel Mode Falcon-Node-Sensor will be deployed via Helm Chart

### Tear Down

NOTE: This demo will place you in a session to the `helper` VM which you must exit to tear down the environment.

```
cd ~/falcon-container-terraform && /bin/bash/demo down
```

### Developer guide

 - Get access to the admin VM that manages the AKS environment
```
cd ~/falcon-container-terraform
ssh azadmin@$(terraform output vm_public_ip | tr -d '"') -i ~/.ssh/container_lab_ssh_key
```

### Troubleshooting

- Troubleshoot admin VM
From a session on the admin VM, read MOTD message or if no message exists run the following command
```
tail /etc/motd.log
```

### Known limitations

 - This is early version. Please report or even fix issues.
 - This code is not intended to be run consecutively. Subsequent runs may fail if clean up is not performed.
