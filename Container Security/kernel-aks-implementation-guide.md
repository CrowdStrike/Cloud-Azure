# Implementation Guide for CrowdStrike Falcon Sensor for Linux on Azure AKS Kubernetes cluster using Helm Chart

This guide works through creation of a new Kubernetes cluster, deployment of the Falcon Sensor for Linux using Helm Chart, and demonstration of detection capabilities of Falcon Container Workload Protection.

No prior Kubernetes or Falcon knowledge is needed to follow this guide. First sections of this guide focus on creation of ACR Container registry and an AKS cluster, however, these sections may be skipped if you have access to an existing cluster.

Time needed to follow this guide: 45 minutes.

## Pre-requisites

- Existing Azure Subscription and Global Adminstrator permissions
- You will need a workstation to complete the installation steps below
  * These steps have been tested on Linux and should also work with OSX
- Install [docker](https://www.docker.com/products/docker-desktop) container runtime
- Verify docker daemon is running on your workstation
- API Credentials from Falcon with Sensor Download Permissions
  * These credentials can be created in the Falcon platform under Support->API Clients and Keys.
  * For this step and practice of least privilege, you would want to create a dedicated API secret and key.
- Azure Cli installed locally and authenticated
  ```
    az login
  ```

## Deployment

### Step 1: Setup an Azure Container Registry

- Set your ACR registry name and resource group name into variables
```
    CLOUD_REGION=westus
    ACR_NAME=csDemoAcr01
    RG_NAME=rg_cswest
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
```
- Notate the login server from the output shown above and add to new variable
```
  ACR_LOGINSERVER=csdemoacr01.azurecr.io
```

### Step 2: Create and upload containerized falcon-sensor

- Set the required variables for falcon-sensor download

```
    FALCON_CLIENT_ID=1234567890ABCDEFG1234567890ABCDEF
    FALCON_CLIENT_SECRET=1234567890ABCDEFG1234567890ABCDEF
    CID=1234567890ABCDEFG1234567890ABCDEF-12
```
- Use the container-image-tools to build a containerized falcon-sensor
- Note: This demo uses the ubuntu18 image which was supported as of this writing

```
    docker run --privileged=true \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ~/.azure:/root/.azure \
        -e FALCON_CLIENT_ID="$FALCON_CLIENT_ID" \
        -e FALCON_CLIENT_SECRET="$FALCON_CLIENT_SECRET" \
        -e CID="$CID" \
        quay.io/crowdstrike/cloud-tools-image falcon-node-sensor-build ubuntu18
```
Example output:
```
    #8 [4/5] COPY entrypoint.sh /
    #8 sha256:d0ef4c755fb66783bcdb499d654eed759c9c7c502bb59b4fbd99f0260d8cb087
    #8 DONE 0.0s

    #9 [5/5] WORKDIR /opt/CrowdStrike
    #9 sha256:2e014e9081abac8653e3815083483b61e27e2cd1c9840d90588b9a92bf53c9e8
    #9 DONE 0.0s

    #10 exporting to image
    #10 sha256:e8c613e07b0b7ff33893b694f7759a10d42e180f2b4dc349fb57dc6b71dcab00
    #10 exporting layers
    #10 exporting layers 0.1s done
    #10 writing image sha256:594d7510f2768cd43fc44dbb1342a9e73be76b9123217fb22a8ab40b4937db0e done
    #10 naming to docker.io/library/falcon-node-sensor:latest done
    #10 DONE 0.1s
    REPOSITORY           TAG       IMAGE ID       CREATED                  SIZE
    falcon-node-sensor   latest    594d7510f276   Less than a second ago   83.7MB
    Contaner falcon-node-sensor:latest has been built successfully
```
- Tag the image created for your ACR
```
    docker tag falcon-node-sensor:latest $ACR_LOGINSERVER/falcon-node-sensor:latest
```
- Authenticate to the ACR
```
    az acr login -n $ACR_NAME
```
Example output:
```
    Uppercase characters are detected in the registry name. When using its server url in docker commands, to avoid authentication errors, use all lowercase.
    Login Succeeded
```
- Upload the falcon-container-sensor to the ACR you created previously
```
    docker push $ACR_LOGINSERVER/falcon-node-sensor:latest
```

### Step 2: Create the AKS cluster and deploy the falcon-helm chart

- Set the name of the AKS Cluster into a variable
```
    AKS_CLUSTER=csAksCluster01
```
- Create the AKS Cluster and attach the ACR
```
    az aks create --name $AKS_CLUSTER --kubernetes-version 1.18.14 --attach-acr $ACR_NAME -g $RG_NAME
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
```
- Install kubectl
```
    az aks install-cli
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
- Install helm using the below command
```
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
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
- List the pods deployed by the helm chart and verify they are runnning
```
    kubectl get pods -n falcon-system
```
Example output:
```
    NAME                              READY   STATUS    RESTARTS   AGE
    falcon-helm-falcon-sensor-4ffwz   2/2     Running   0          38s
    falcon-helm-falcon-sensor-l2c5w   2/2     Running   0          45s
    falcon-helm-falcon-sensor-t7rxz   2/2     Running   0          38s
```
- (optional) Verify that given pod has registered with CrowdStrike Falcon and received unique identifier.
```
     for i in $(kubectl get pods -n falcon-system | awk 'FNR > 1' | awk '{print $1}')
     do 
              echo "$i - $(kubectl exec $i -n falcon-system -c falcon-node-sensor -- falconctl -g --aid)"
     done
```
Example output:
```
     falcon-helm-falcon-sensor-XXXX - aid="a582XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```
- (optional) Check the Reduced Functionality Mode state of the Falcon Sensor.
- Note that the value returned should be false if running on supported kernel and platform versions.
```
     for i in $(kubectl get pods -n falcon-system | awk 'FNR > 1' | awk '{print $1}')
     do 
           echo "$i - $(kubectl exec $i -n falcon-system -c falcon-node-sensor -- falconctl -g --rfm-state)"
     done
```
Example output:
```
    falcon-helm-falcon-sensor-4ffwz - rfm-state=false.
    falcon-helm-falcon-sensor-l2c5w - rfm-state=false.
    falcon-helm-falcon-sensor-t7rxz - rfm-state=false.
```
### Step 3: (Optional) Deploy the vulnapp project to the cluster and test detections

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
```
    echo "http://$(kubectl get service vulnerable-example-com  -o yaml -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")/"
```
Example output:
```
http://111.11.111.111/
```
- Visit this web address and use the links to test detections
- Tear down the vulnapp deployment

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
