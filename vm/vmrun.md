# Azure Virtual Machine Run Command

The Run Command uses Azure's virtual machine agent to run scripts on your virtual machines running in Azure. Generally, the Run Command is useful for running commands on single VM instances.
The Run Command can be run with the Azure CLI, the Azure portal, or REST API and is capable of running PowerShell or shell scripts.

This article provides an overview of using a Run command that will install the CrowdStrike Falcon sensor on a single VM instance in Azure. For more information on the Run Command, see the [Run Command documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/run-command-overview).

## Using Run Command on a Linux instance

The following example runs the Run Command a Linux VM named *myVM* in a resource group named *myResourceGroup*. Replace the example resource group name, VM name, and script environment variables to run (https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh) with your own information. For more Azure specific documentation using the Run Command, see [https://docs.microsoft.com/en-us/azure/virtual-machines/linux/run-command](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/run-command)

```azurecli
az vm run-command invoke -g myResourceGroup -n myVm \
  --command-id RunShellScript \
  --scripts 'export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && curl -L https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh | bash'
```
