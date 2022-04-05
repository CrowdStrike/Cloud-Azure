# Implementation Guide for CrowdStrike Falcon Sensor for Linux on Azure AKS Kubernetes cluster using Helm Chart

This guide works through creation of a new Kubernetes cluster, deployment of the Falcon Sensor for Linux DaemonSet using Helm Chart, and demonstration of detection capabilities of Falcon Container Workload Protection.

No prior Kubernetes or Falcon knowledge is needed to follow this guide. First sections of this guide focus on creation of ACR Container registry and an AKS cluster, however, these sections may be skipped if you have access to an existing cluster.

Time needed to follow this guide: 45 minutes.

## Pre-requisites

- Existing Azure Subscription and Global Administrator permissions
- You will need a workstation to complete the installation steps below
  * These steps have been tested on Linux and should also work with OSX
- Install [docker](https://www.docker.com/products/docker-desktop) container runtime
- Verify docker daemon is running on your workstation
- API Credentials from Falcon with Sensor Download Permissions
  * These credentials can be created in the Falcon platform under Support->API Clients and Keys.
  * For this step and practice of least privilege, you would want to create a dedicated API secret and key.
- Install helm using the below command
```
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
- Azure Cli installed locally and authenticated

```
    az login
```
- Install kubectl
```
    az aks install-cli
```


## Deployment


### Step 1: Setup an Azure Container Registry

- Set your ACR registry name and resource group name into variables
- Note: The ACR_NAME must be a unique name globally as a DNS record is created to reference the image registry
```
    CLOUD_REGION=<region>
    ACR_NAME=<arc_unique_name>
    RG_NAME=<resource_group_name>
```
- Create the resource group for the ACR and Cluster
```
    az group create --name $RG_NAME --location $CLOUD_REGION
```
- Create the Azure Container Registry
```
    az acr create --name $ACR_NAME --sku basic -g $RG_NAME --location $CLOUD_REGION
```
  Example output:
```
    [
    {
        "adminUserEnabled": false,
        "anonymousPullEnabled": false,
        "creationDate": "2021-04-16T21:12:03.724818+00:00",
        "dataEndpointEnabled": false,
        "dataEndpointHostNames": [],
        "encryption": {
        "keyVaultProperties": null,
        "status": "disabled"
        },
        "id": "/subscriptions/9da62014-f7c1-4e8f-9241-14a2b28362f1/resourceGroups/rg_cswest/providers/Microsoft.ContainerRegistry/registries/csDemoAcr01",
        "identity": null,
        "location": "westus",
        "loginServer": "csdemoacr01.azurecr.io",
        "name": "csDemoAcr01",
        "networkRuleBypassOptions": "AzureServices",
        "networkRuleSet": null,
        "policies": {
        ....
```
- Notate the login server from the output shown above and add to a new variable
```
  ACR_LOGINSERVER=csdemoacr01.azurecr.io
```


### Step 2: Clone the falcon sensor for linux daemonset image
- Authenticate to the ACR
```
    az acr login -n $ACR_NAME
```
Example output:
```
    Uppercase characters are detected in the registry name. When using its server url in docker commands, to avoid authentication errors, use all lowercase.
    Login Succeeded
```
- Set the required variables for falcon-sensor download
```
    FALCON_CLIENT_ID=1234567890ABCDEFG1234567890ABCDEF
    FALCON_CLIENT_SECRET=1234567890ABCDEFG1234567890ABCDEF
    CID=1234567890ABCDEFG1234567890ABCDEF-12
```
- Use the container-image-tools to clone the falcon sensor for linux daemonset image to ACR.
```
    docker run --privileged=true \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ~/.azure:/root/.azure \
        -e FALCON_CLIENT_ID="$FALCON_CLIENT_ID" \
        -e FALCON_CLIENT_SECRET="$FALCON_CLIENT_SECRET" \
        -e CID="$CID" \
        quay.io/crowdstrike/cloud-tools-image falcon-node-sensor-push $ACR_LOGINSERVER/falcon-node-sensor

### Step 3: Create the AKS cluster and deploy the falcon-helm chart
```
- Set the name of the AKS Cluster into a variable
```
    AKS_CLUSTER=csAksCluster01
```
- Create the AKS Cluster and attach the ACR
```
    az aks create --name $AKS_CLUSTER --kubernetes-version 1.18.14 --attach-acr $ACR_NAME -g $RG_NAME --generate-ssh-keys
```
Example output:
```
    AAD role propagation done[############################################]  100.0000%{
    "aadProfile": null,
    "addonProfiles": {
        "KubeDashboard": {
        "config": null,
        "enabled": false,
        "identity": null
        }
    },
    "agentPoolProfiles": [
        {
        "availabilityZones": null,
        "count": 3,
        "enableAutoScaling": null,
        "enableEncryptionAtHost": null,
        "enableNodePublicIp": false,
        "kubeletConfig": null,
        "kubeletDiskType": "OS",
        "linuxOsConfig": null,
        "maxCount": null,
        "maxPods": 110,
        "minCount": null,
    ...
```
- Get the cluster config and credentials
```
    az aks get-credentials --name $AKS_CLUSTER -g $RG_NAME
```
- Run kubectl command to verify connectivity
```
    kubectl get nodes
```
Example output:
```
    NAME                                STATUS   ROLES   AGE     VERSION
    aks-nodepool1-25659352-vmss000000   Ready    agent   6m48s   v1.18.14
    aks-nodepool1-25659352-vmss000001   Ready    agent   7m8s    v1.18.14
    aks-nodepool1-25659352-vmss000002   Ready    agent   6m51s   v1.18.14
```
- Add the falcon-helm repository
```
    helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
```
Example output:
```
    "crowdstrike" has been added to your repositories
```
- Deploy the falcon-sensor
```
    helm upgrade --install falcon-helm crowdstrike/falcon-sensor \
        -n falcon-system --create-namespace \
        --set falcon.cid=$CID \
        --set node.image.repository=$ACR_LOGINSERVER/falcon-node-sensor
```
Example output:
```
    Release "falcon-helm" does not exist. Installing it now.
    NAME: falcon-helm
    LAST DEPLOYED: Fri Apr 16 17:12:31 2021
    NAMESPACE: falcon-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    You should be a Crowdstrike customer and have access to the Falcon Linux Sensor
    and Falcon Container Downloads to install this helm chart and have it work
    correctly as a specialized container has to exist in the container registry
    before this chart will install properly.

    The CrowdStrike Falcon sensor should be spinning up on all your kubernetes nodes
    now. There should be no further action on your part unless no Falcon Sensor
    container exists in your registry. If you forgot to add a Falcon Sensor image to
    your image registry before you ran `helm install`, please add the Falcon Sensor
    now; otherwise, pods will fail with errors and crash until there is a valid
    image to pull. The default image name to deploy a kernel sensor to a node is
    `falcon-node-sensor`.
```
- List the pods deployed by the helm chart and verify they are running
```
    kubectl get pods -n falcon-system
```
Example output:
```
    NAME                              READY   STATUS    RESTARTS   AGE
    falcon-helm-falcon-sensor-4ffwz   1/1     Running   0          38s
    falcon-helm-falcon-sensor-l2c5w   1/1     Running   0          45s
    falcon-helm-falcon-sensor-t7rxz   1/1     Running   0          38s
```
- (optional) Verify that Falcon Sensor for Linux has insert itself to the kernel
 - Note that this must be done on Kubernetes worker nodes so access to these nodes is required for this step. You can access worker nodes through the daemonset pods.
    ```
    $ kubectl exec <podname> -n falcon-system --stdin --tty -- /bin/sh
    $ lsmod | grep falcon
    falcon_lsm_serviceable     724992  1
    falcon_nf_netcontain        20480  1
    falcon_kal                  45056  1 falcon_lsm_serviceable
    falcon_lsm_pinned_11110     45056  1
    falcon_lsm_pinned_11308     45056  1
    ```

### Step 4: (Optional) Deploy the vulnapp project to the cluster and test detections

- Deploy the vulnapp manifest to cluster
```
    kubectl apply -f  https://raw.githubusercontent.com/isimluk/vulnapp/master/vulnerable.example.yaml
```
Example output:
```
    deployment.apps/vulnerable.example.com created
    service/vulnerable-example-com created
```
- Retrieve the  external IP address from the vulnapp service
- Note: This may need to be ran multiple times while the ingress service is built
```
    echo "http://$(kubectl get service vulnerable-example-com  -o yaml -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")/"
```
Example output:
```
http://111.11.111.111/
```
- Visit this web address and use the links to test detections
- Tear down the vulnapp deployment
```
    kubectl delete -f  https://raw.githubusercontent.com/isimluk/vulnapp/master/vulnerable.example.yaml
```

### Step 3: Tear down the demo

- Uninstall the falcon-helm deployment
```
    helm uninstall falcon-helm -n falcon-system
```
Example output:
```
    release "falcon-helm" uninstalled
```
- Run the delete cluster command and select Y when prompted
```
    az aks delete --name $AKS_CLUSTER -g $RG_NAME
```
- Run the delete ACR command and select Y when prompted
```
    az acr delete --name $ACR_NAME -g $RG_NAME
```
- Run the delete resource group command and select Y when prompted
```
    az group delete --name $RG_NAME
```
