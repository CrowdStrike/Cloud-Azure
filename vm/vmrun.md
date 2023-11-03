# Azure Virtual Machine Run Command

The Run Command uses Azure's virtual machine agent to run scripts on your virtual machines running in Azure. Generally, the Run Command is useful for running commands on single VM instances.
The Run Command can be run with the Azure CLI, the Azure portal, or REST API and is capable of running PowerShell or shell scripts.

This article provides an overview of using a Run command that will install the CrowdStrike Falcon sensor on a single VM instance in Azure. For more information on the Run Command, see the [Run Command documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/run-command-overview).

> [!NOTE]
> The Run Command is not supported on VMs that are not running. If you are using the Run Command to install the CrowdStrike Falcon sensor, you must first start the VM.

## Using Run Command on Linux

The following example runs the Run Command on a Linux VM named *myVM* in a resource group named *myResourceGroup*.

Replace the example resource group name, VM name, and script environment variables to run (https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh) with your own information.

For more Azure specific documentation using the Run Command on Linux, see the [Azure docs](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/run-command).

```azurecli
az vm run-command invoke -g myResourceGroup -n myVm \
  --command-id RunShellScript \
  --scripts 'export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && curl -L https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh | bash'
```

To use the Run Command on multiple VMs, use the `az vm run-command invoke` command with the `--ids` parameter. The following example runs the Run Command on all VMs in a resource group named *myResourceGroup*.

```azurecli
az vm run-command invoke --ids $(az vm list -g myResourceGroup --query "[].id" -o tsv) \
  --command-id RunShellScript \
  --scripts 'export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && curl -L https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh | bash'
```

## Using Run Command on Windows

The following example runs the Run Command on a Windows VM named *myVM* in a resource group named *myResourceGroup*.

Replace the example resource group name, VM name, and script environment variables to run (https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/powershell/install/falcon_windows_install.ps1) with your own information.

For more Azure specific documentation using the Run Command on Windows, see the [Azure docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/run-command).

> [!IMPORTANT]
> Ensure the target VM's support TLS 1.2 or later. If you see errors related to TLS, try prepending `--scripts` with the following: `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;`. See TLS example below.

```azurecli
az vm run-command invoke -g myResourceGroup -n myVm \
  --command-id RunPowerShellScript \
  --scripts 'Invoke-WebRequest -Uri https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/powershell/install/falcon_windows_install.ps1 -Outfile falcon_windows_install.ps1; .\falcon_windows_install.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789'
```

Example using TLS 1.2 or later:

```azurecli
az vm run-command invoke -g myResourceGroup -n myVm \
  --command-id RunPowerShellScript \
  --scripts '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/powershell/install/falcon_windows_install.ps1 -Outfile falcon_windows_install.ps1; .\falcon_windows_install.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789'
```

To use the Run Command on multiple VMs, use the `az vm run-command invoke` command with the `--ids` parameter. The following example runs the Run Command on all VMs in a resource group named *myResourceGroup*.

```azurecli
az vm run-command invoke --ids $(az vm list -g myResourceGroup --query "[].id" -o tsv) \
  --command-id RunPowerShellScript \
  --scripts 'Invoke-WebRequest -Uri https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/powershell/install/falcon_windows_install.ps1 -Outfile falcon_windows_install.ps1; .\falcon_windows_install.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789'
```
