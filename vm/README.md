# Azure Virtual Machines


## Deploying CrowdStrike Falcon

There are multiple ways to deploy the CrowdStrike Falcon sensor to Virtual Machines in Azure regardless of whether the Virtual Machine is standalone or launched as part of a Virtual Machine Scale Set.

The following articles show ways to deploy in Azure

| Integration Name | Description |
|:-|:-|
| [VM Extensions](vm-extensions) | Examples for utilizing Linux VM Custom script extensions to deploy Falcon Kernel Mode Sensor to Azure VM Linux workloads |
| [VM Run Command](vmrun.md) | Examples for deploying the Falcon Sensor to a single VM using the Run command |
| [VM Applications](vmapp/README.md) | Examples for using Azure VM Applications to deploy the Falcon Sensor |
| [Virtual Machine Scale Sets (VMSS)](vmss) | Examples for deploying Virtual Machine Scale Sets that install Falcon Sensor on instance launch |