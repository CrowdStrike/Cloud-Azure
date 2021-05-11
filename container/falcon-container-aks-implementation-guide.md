# Implementation Guide for CrowdStrike Falcon-Container Sensor on Azure AKS Kubernetes cluster

This guide works through creation of a new Kubernetes cluster, deployment of the Falcon-Container Sensor, and demonstration of detection capabilities of Falcon Container Workload Protection.

No prior Kubernetes or Falcon knowledge is needed to follow this guide. First sections of this guide focus on creation of ACR Container registry and an AKS cluster, however, these sections may be skipped if you have access to an existing cluster.

Time needed to follow this guide: 45 minutes.

## Pre-requisites

- Refer to the lastest documentation on the [falcon-container](https://falcon.crowdstrike.com/documentation/146/falcon-container-sensor-for-linux)
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
- Install kubectl
```
az aks install-cli
```

## Deployment


### Step 1: Setup an Azure Container Registry

- Set your ACR registry name and resource group name into variables
- Note: The ACR_NAME must be a unique name globally as a DNS record is created to reference the image registry
```
CLOUD_REGION=westus
ACR_NAME=<arc_unique_name>
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
        ....
```
- Notate the login server from the output shown above and add to a new variable
```
ACR_LOGINSERVER=csdemoacr01.azurecr.io
```

### Step 2: Download the falcon-container sensor

Note: For existing ACR set the loginServer attribute from the ACR to the following variable.
```
ACR_LOGINSERVER=<loginServer>
```
- Set the FALCON_IMAGE_UI variable to the full path of the tagged image and repository for future use
```
FALCON_IMAGE_URI=$ACR_LOGINSERVER/falcon-sensor:latest
```
- Login to the Falcon Platform and Navigate to Hosts->Sensor Downloads

- Download the latest 'Container' sensor (Support for AKS was added in 6.23.601)

- Import the tarball to your local docker. If you are following this guide inside the tooling container, you can run this command outside of the container as the docker socket is shared between your host system and the said tooling container.
```
docker load -i falcon-sensor-6.23.0-601.container.x86_64.tar.bz2
```
Example output:
```
ad2fea6dc0f1: Loading layer [==================================================>]   78.6MB/78.6MB
Loaded image: falcon-sensor:6.23.0-601.container.x86_64.Release.US1
```
- List the loaded docker image
```
docker images | grep falcon-sensor
```
Example output:
```
   falcon-sensor  6.23.0-601.container.x86_64.Release.US1   e618c8efcc93   2 weeks ago    78.5MB
```
- Note the image name and the image tag in the first and second columns respectively
- Using the local image name and tag, re-tag the image for your managed ECR using the variable previously set
```
docker tag falcon-sensor:6.23.0-601.container.x86_64.Release.US1 $FALCON_IMAGE_URI
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
docker push $FALCON_IMAGE_URI
```

### Step 3: Create the AKS cluster

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

### Step 4: Install the Admission Controller and Injector POD

Admission Controller is Kubernetes service that intercepts requests to the Kubernetes API server. Falcon Container Sensor hooks to this service and injects Falcon Container Sensor to any new pod deployment on the cluster. In this step we will configure and deploy the admission hook and the admission application.

- Provide CrowdStrike Falcon Customer ID as environment variable. This CID will be later used to register newly deployed pods to CrowdStrike Falcon platform.
```
CID=1234567890ABCDEFG1234567890ABCDEF-12
```
- Install the admission controller
```
docker run --rm --entrypoint installer $FALCON_IMAGE_URI \
    -cid $CID -image $FALCON_IMAGE_URI \
    | kubectl apply -f -
```
Example output:
```
namespace/falcon-system created
configmap/injector-config created
secret/injector-tls created
deployment.apps/injector created
service/injector created
mutatingwebhookconfiguration.admissionregistration.k8s.io/injector.falcon-system.svc created
```
- (Optional) Watch the progress of a deployment
```
kubectl get pods -n falcon-system -w
```
Example output:
```
NAME                        READY   STATUS    RESTARTS   AGE
injector-6499dbd4b5-v5gqr   1/1     Running   0          2d3h
```
- (optional) Run the installer with --help command-line argument to output available configuration options for the deployment.
```
docker run --rm --entrypoint installer $FALCON_IMAGE_URI --help
usage:
  -cid string
    	Customer id to use
  -days int
    	Validity of certificate in days. (default 3650)
  -falconctl-env value
    	FALCONCTL options in key=value format.
  -image string
    	Image URI to load (default "crowdstrike/falcon")
  -mount-docker-socket
    	A boolean flag to mount docker socket of worker node with sensor.
  -namespaces string
    	Comma separated namespaces with which image pull secret need to be created, applicable only with -pullsecret (default "default")
  -pullpolicy string
    	Pull policy to be defined for sensor image pulls (default "IfNotPresent")
  -pullsecret string
    	Secret name that is used to pull image (default "crowdstrike-falcon-pull-secret")
  -pulltoken string
    	Secret token, stringified dockerconfig json or base64 encoded dockerconfig json, that is used with pulling image
  -sensor-resources string
    	A valid json string or base64 encoded string of the same, which is used as k8s resources specification.
```
### Step 5: (Optional) Deploy the vulnapp project to the cluster and test detections

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

### Step 6: Tear down the demo

- Remove the falcon-container sensor deployment
```
docker run --rm --entrypoint installer $FALCON_IMAGE_URI \
    -cid $CID -image $FALCON_IMAGE_URI \
    | kubectl delete -f -
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
