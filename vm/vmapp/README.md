# Azure Virtual Machine Application

Azure Virtual Machine Applications allow you the ability to simplify the management and distribution of your organizations applications without having to manage Virtual Machine images.
It effectively replaces the third-party vendor provided VM Extensions. VM Applications use multiple the following Azure resources:

- Azure Compute Gallery
- VM Application
- VM Application version

Azure VM Applications can be created with the Azure CLI, PowerShell, REST API, and the Azure portal. It is really important to know that VM Applications are currently in public preview. To learn more about VM Applications, see [the VM Application documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/vm-applications)

## Prerequisites

To begin with Azure VM Applications, an Azure Compute Gallery and Azure Storage Account must exist and be accessible to the region(s) that you will be utilizing the Azure VM Application.

1. If a gallery does not exist already, create an Azure Compute Gallery.
    ```azurecli
    az group create --name myGalleryRG --location eastus
    az sig create --resource-group myGalleryRG --gallery-name myGallery
    ```
    See the [the Azure Compute Gallery documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries) for more information about galleries.
2. If a storage account does not exist already, create an Azure Storage account.
    ```azurecli
    az group create --name storage-resource-group --location eastus
    az storage account create \
      --name myStorageAccount \
      --resource-group storage-resource-group \
      --location eastus \
      --sku Standard_RAGRS \
      --kind StorageV2
    ```
3. Create a container to store the sensor packages
    ```azurecli
    az storage container create \
      --name myContainer \
      --account-name myStorageAccount \
      --auth-mode login
    ```
    When using the package or the installer deployment, it is really important to understand the permissions must be setup correctly for access to the storage container such that there is not exposure of the Falcon sensor to anonymous downloads or use.

## Falcon Sensor Installer Deployment using VM Applications (Preferred Method)

This method uses scripts to download the Falcon Sensor from CrowdStrike and install the Falcon Sensor to virtual machines as a VM Application.
It will use a smaller amount of hard drive space due to the small size of the scripts.

### Falcon Linux Sensor VM Application

1. Download the CrowdStrike Falcon install script from [https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh](https://raw.githubusercontent.com/crowdstrike/falcon-scripts/main/bash/install/falcon-linux-install.sh)

1. Upload the CrowdStrike Falcon install script to the storage container for access for the VM Application.
    ```azurecli
    az storage blob upload --file /path/to/falcon-linux-install.sh --container-name myContainer --account-name myStorageAccount
    ```
2. Create an Azure Gallery application for a Linux Operating System.
    ```azurecli
    az sig gallery-application create \
      --resource-group myGalleryRG \
      --gallery-name myGallery \
      --name CrowdStrike-Falcon-Linux-Installer \
      --description "CrowdStrike Falcon Linux Sensor Installer" \
      --os-type Linux
    ```
3. Create a version definition of the Azure Gallery application changing any of the arguments as needed.
    ```azurecli
    az sig gallery-application version create \
      --version-name 1.0.0 \
      --application-name CrowdStrike-Falcon-Linux-Installer \
      --gallery-name myGallery \
      --location "East US" \
      --resource-group myGalleryRG \
      --package-file-link "https://myStorageAccount.blob.core.windows.net/myContainer/falcon-linux-install.sh" \
      --install-command "mv CrowdStrike-Falcon-Linux-Installer falcon-linux-install.sh && export FALCON_CLIENT_ID=123456789f1c4a0d9987a45123456789 && export FALCON_CLIENT_SECRET=ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 && bash falcon-linux-install.sh" \
      --remove-command "export FALCON_UNINSTALL=true && bash falcon-linux-install.sh"
    ```
    Make sure to keep some iteration of `mv CrowdStrike-Falcon-Linux-Installer falcon-linux-install.sh` in `--install-command`. Otherwise, the application will fail to install.

### Falcon Windows Sensor VM Application

1. In the CrowdStrike console, ensure the following API scopes are enabled for your OAuth client ID and secret:

  - Install:
    - **Sensor Download** [read]
    - **Sensor update policies** [read]
  - Uninstall:
    - **Host** [write]
    - **Sensor update policies** [write]

2. Download the CrowdStrike Falcon install scripts zip file from [https://github.com/crowdstrike/falcon-scripts/releases/latest/download/falcon_windows_install_scripts.zip](https://github.com/crowdstrike/falcon-scripts/releases/latest/download/falcon_windows_install_scripts.zip)

3. Upload the CrowdStrike Falcon install scripts zip file to the storage container for access for the VM Application.
    ```azurecli
    az storage blob upload --file /path/to/falcon_windows_install_scripts.zip --container-name myContainer --account-name myStorageAccount
    ```
4. Create an Azure Gallery application for the Microsoft Windows Operating System.
    ```azurecli
    az sig gallery-application create \
      --resource-group myGalleryRG \
      --gallery-name myGallery \
      --name CrowdStrike-Falcon-Windows-Installer \
      --description "CrowdStrike Falcon Windows Sensor" \
      --os-type Windows
    ```
5. Create a version definition of the Azure Gallery application changing any of the arguments as needed.
    ```azurecli
    az sig gallery-application version create \
      --version-name 1.0.0 \
      --application-name CrowdStrike-Falcon-Windows-Installer \
      --gallery-name myGallery \
      --location "East US" \
      --resource-group myGalleryRG \
      --package-file-name falcon.zip \
      --package-file-link "https://myStorageAccount.blob.core.windows.net/myContainer/falcon_windows_install_scripts.zip" \
      --install-command 'powershell.exe -Command "Expand-Archive falcon.zip -DestinationPath C:\ProgramData\CrowdStrike; C:\ProgramData\CrowdStrike\falcon_windows_install.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789' \
      --remove-command 'powershell.exe -Command "C:\ProgramData\CrowdStrike\falcon_windows_uninstall.ps1"'
    ```
    You can alternatively configure the uninstall command to retrieve the maintenance token as well as remove the host from the CrowdStrike Falcon console. For example:
    ```
    powershell.exe -Command "C:\ProgramData\CrowdStrike\falcon_windows_uninstall.ps1 -FalconClientId 123456789f1c4a0d9987a45123456789 -FalconClientSecret ABCDEFGHtwfk6c0U4l72EsnjXxS1mH9123456789 -RemoveHost"
    ```
    For a complete list of install/uninstall script CLI flags that can be used as well as more information on the scripts themselves, see [https://github.com/CrowdStrike/falcon-scripts/tree/main/powershell/install](https://github.com/CrowdStrike/falcon-scripts/tree/main/powershell/install).

## Falcon Sensor Package Deployment using VM Applications (Alternate Method)

This method uses the CrowdStrike Falcon installation packages to install the Falcon Sensor to virtual machines as a VM Application.
It will use a larger amount of hard drive space based on the sensor install packages and any dependencies that may need to be bundled with the install.

### Falcon Windows Sensor VM Application

1. Upload the CrowdStrike Falcon sensor to the storage container for access for the VM Application. In this example, the `WindowsSensor.exe` is the package that will get uploaded to the storage container.
    ```azurecli
    az storage blob upload --file /path/to/WindowsSensor.exe --container-name myContainer --account-name myStorageAccount
    ```
2. Create an Azure Gallery application for the Microsoft Windows Operating System.
    ```azurecli
    az sig gallery-application create \
      --resource-group myGalleryRG \
      --gallery-name myGallery \
      --name CrowdStrike-Windows \
      --description "CrowdStrike Falcon Windows Sensor" \
      --os-type Windows
    ```
3. Create a version definition of the Azure Gallery application changing any of the arguments as needed.
    ```azurecli
    az sig gallery-application version create \
      --version-name 1.0.0 \
      --application-name CrowdStrike-Windows \
      --gallery-name myGallery \
      --location "East US" \
      --resource-group myGalleryRG \
      --package-file-link "https://myStorageAccount.blob.core.windows.net/myContainer/WindowsSensor.exe" \
      --install-command "move .\\CrowdStrike-Windows .\\WindowsSensor.exe & WindowsSensor.exe /install /quiet /norestart CID=1234567890ABCDEF1234567890ABCDEF-12" \
      --remove-command '"C:\ProgramData\Package Cache\{3f6ddd3f-d7a9-4415-9a6d-716bfd222cfd}\WindowsSensor.exe" /uninstall /quiet'
    ```
    Make sure to keep some iteration of `move .\\CrowdStrike-Windows .\\WindowsSensor.exe & WindowsSensor.exe` in `--install-command`. Otherwise, the application will fail to install.

### Falcon Linux Sensor VM Application

1. Upload the CrowdStrike Falcon sensor to the storage container for access for the VM Application. In this example, the `falcon-sensor-6.32.0-12904.el8.x86_64.rpm` for a Red Hat Enterprise Linux 8 system is the package that will get uploaded to the storage container.
    ```azurecli
    az storage blob upload --file /path/to/falcon-sensor-6.32.0-12904.el8.x86_64.rpm --container-name myContainer --account-name myStorageAccount
    ```
2. Create an Azure Gallery application for a Linux Operating System.
    ```azurecli
    az sig gallery-application create \
      --resource-group myGalleryRG \
      --gallery-name myGallery \
      --name CrowdStrike-Linux \
      --description "CrowdStrike Falcon Linux Sensor" \
      --os-type Linux
    ```
3. Create a version definition of the Azure Gallery application changing any of the arguments as needed.
    ```azurecli
    az sig gallery-application version create \
      --version-name 1.0.0 \
      --application-name CrowdStrike-Linux \
      --gallery-name myGallery \
      --location "East US" \
      --resource-group myGalleryRG \
      --package-file-link "https://myStorageAccount.blob.core.windows.net/myContainer/falcon-sensor-6.32.0-12904.el8.x86_64.rpm" \
      --install-command "mv CrowdStrike-Linux falcon-sensor-6.32.0-12904.el8.x86_64.rpm && yum -y install falcon-sensor-6.32.0-12904.el8.x86_64.rpm && /opt/CrowdStrike/falconctl -s --cid=1234567890ABCDEF1234567890ABCDEF-12" && systemctl enable --now falcon-sensor \
      --remove-command "yum -y remove falcon-sensor"
    ```
    Make sure to keep some iteration of `mv CrowdStrike falcon-sensor-6.32.0-12904.el8.x86_64.rpm` in `--install-command`. Otherwise, the application will fail to install.
