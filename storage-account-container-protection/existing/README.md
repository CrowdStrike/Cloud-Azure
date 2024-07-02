![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png) [![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>

# Azure Storage Account Container Protection demonstration

This demonstration leverages Terraform to provide a functional demonstration of this integration.
All of the necessary resources for using this solution to protect an existing Azure Storage Account Container are implemented for you as part of the environment configuration process, including sample files and command line helper scripts.

## Contents

+ `app_insights.tf` - The configuration details for the Function App application insights.
+ `app_service_plan.tf` - Service plan configuration for the Function App.
+ `function_app.tf` - Configuration for the Function App that will be triggered.
+ `main.tf` - The main terraform configuration. Defines the required providers.
+ `outputs.tf` - The values output by Terraform after the stand-up process completes.
+ `provider.tf` - Configuration for all the providers that will be used for terraform deployment.
+ `resource_group.tf` - Resource group to contain all the resources that will be deployed for the demo.
+ `storage_account.tf` - Storage account for the Function App logs.
+ `terraform.tfvars` - Variable values.
+ `variables.tf` - User customizable values used by the integration and demonstrations.

> Please note: If you use the `existing.sh` helper script provided in the root folder for this integration, you should not need to modify these files.

## Setup

### CrowdStrike Falcon API Credentials

Create or modify an API Key in the Falcon Console and
Assign the following scopes:

+ Quick Scan - `READ`, `WRITE`
+ Sample Uploads - `READ`,`WRITE`

> You will be asked to provide these credentials when the `existing.sh` script executes.

> This demonstration has been tested using Azure Cloud Shell

Next, you will be standing up an environment for this demonstration

## Let's Get Started

Login to your Azure subscription

[Launch Cloud Shell](https://shell.azure.com)

Clone this repository by running the following commands

```shell
git clone https://github.com/CrowdStrike/Cloud-Azure.git
```

Navigate to the Cloud-Azure/storage-account-container-protection directory

```
cd Cloud-Azure/storage-account-container-protection
```

Execute the following command to stand up the demonstration

***Please note that the input for your credentials are hidden.***

```sh
./existing.sh up
```

You will be asked to provide your CrowdStrike API credentials as well as the storage account name, container name, and resource group .

If this is the first time you're executing the demonstration, Terraform will initialize the working folder after you submit these values. After this process completes, Terraform will begin to stand-up the environment.

It takes roughly 3 minutes to stand up the environment.

> [!NOTE]
> Sometimes the step to download the malicious files will error out. The script will attempt to retry the step a maximum 3 times, after which the script will fail. If the script fails, you can simply rerun `./existing.sh up`

When the environment is done, you will be presented with the message:

```terminal

╭━━━┳╮╱╱╭╮╱╱╱╭━━━┳━━━┳━╮╱╭┳━━━╮
┃╭━╮┃┃╱╱┃┃╱╱╱╰╮╭╮┃╭━╮┃┃╰╮┃┃╭━━╯
┃┃╱┃┃┃╱╱┃┃╱╱╱╱┃┃┃┃┃╱┃┃╭╮╰╯┃╰━━╮
┃╰━╯┃┃╱╭┫┃╱╭╮╱┃┃┃┃┃╱┃┃┃╰╮┃┃╭━━╯
┃╭━╮┃╰━╯┃╰━╯┃╭╯╰╯┃╰━╯┃┃╱┃┃┃╰━━╮
╰╯╱╰┻━━━┻━━━╯╰━━━┻━━━┻╯╱╰━┻━━━╯

Welcome to the CrowdStrike Falcon Azure Storage Account Container Protection demo environment!

The name of your storage account is <storage account name>.

The name of your storage account container is <storage account container name>.
...
...
```

---
Next, you'll use the helper commands to upload the sample files, and check for findings.

## Using the Demonstration

Now that your environment is stood up, and your cloud shell is configured, you can start testing functionality.

### Export helper commands path
The demo environment uses a few helper commands to help with certain actions. For the helper commands to work properly, you will need to export the directory path to your PATH variable by running the  commands below.

```sh
export PATH=~/Cloud-Azure/storage-account-container-protection/bin:$PATH
```

### List sample files

Run the following command to list the sample files:

```sh
ls ~/testfiles
```

The folder contains the following sample types:

+ 2 safe sample files
+ 3 malware sample files
+ 2 unscannable sample files

#### Example

```terminal
malicious1.bin  malicious2.bin  malicious3.bin  safe1.bin  safe2.bin  unscannable1.png  unscannable2.jpg
```

### Upload sample files

Run the following command to upload the entire contents of the `~/testfiles` folder to the demonstration bucket:

```sh
upload
```

#### Example

```terminal
Uploading test files, please wait...
Uploading malicious1.bin to quickscancontainer...
Uploading malicious2.bin to quickscancontainer...
Uploading malicious3.bin to quickscancontainer...
Uploading safe1.bin to quickscancontainer...
Uploading safe2.bin to quickscancontainer...
Uploading unscannable1.png to quickscancontainer...
Uploading unscannable2.jpg to quickscancontainer...
Upload complete. Check App insights logs or use the get-findings command for scan results.
```

---
Next, you'll review the output from the Cloud Functions demonstration function.

## Review Application Insights Logs

There are a few ways to view the status of the files uploaded to the demonstration container. Below
you will use the helper command `get-findings` as the main method for this demonstration.

### Use the `get-findings` helper command

Run the following command to view any detected Malware threats:

```sh
get-findings
```

> [!NOTE]
> Although Cloud Shell should already have permissions, you might need to log in to Azure for this command to work by running `az login`. This is a quirk of Azure Cloud Shell

> [!TIP]
> Due to cold starts, it could take up to 10 minutes for Azure Functions to detect the files. You can try opening the Azure function to nudge an invocation, or running the upload command again


#### Example

```terminal
"Threat malicious1.bin removed from bucket quickscancontainer"
"Threat malicious2.bin removed from bucket quickscancontainer"
"Threat malicious3.bin removed from bucket quickscancontainer"
"No threat found in safe1.bin"
"No threat found in unscannable2.jpg"
"No threat found in safe2.bin"
```

### Use the Logging Dashboard (Optional)

The quickest method for viewing the logs on the console is to:

Navigate to the [Function App](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2Fsites/kind/functionapp) service page
-> Select the demo function
-> On the sidebar select `Application Insights`
-> Click "View Application Insights data"
-> On the sidebar click Logs
-> In the text box, type in `traces | where message has "Threat" or message has "Mitigate" | project message`

---
Next, you'll verify the malicious files were removed from the bucket.

## Verify malicious files were deleted

Run the `list-bucket` helper command to list the objects in the demonstration bucket:

```sh
list-bucket
```

#### Example

```terminal
$ list-bucket
"safe1.bin"
"safe2.bin"
"unscannable1.png"
"unscannable2.jpg"
```

Notice the malicious files are not listed. This is good news!

---
Next, you'll tear down the demonstration to prevent your organization from yelling at you about runaway cloud costs ;)

## Tearing Down the Demonstration

To tear down the environment, and clean up any associated files, run the following command:

```sh
./existing.sh down
```

Once the environment has been destroyed and cleaned up, you will be provided the message:

```terminal
Destroy complete! Resources: 8 destroyed.

╭━━━┳━━━┳━━━┳━━━━┳━━━┳━━━┳╮╱╱╭┳━━━┳━━━╮
╰╮╭╮┃╭━━┫╭━╮┃╭╮╭╮┃╭━╮┃╭━╮┃╰╮╭╯┃╭━━┻╮╭╮┃
╱┃┃┃┃╰━━┫╰━━╋╯┃┃╰┫╰━╯┃┃╱┃┣╮╰╯╭┫╰━━╮┃┃┃┃
╱┃┃┃┃╭━━┻━━╮┃╱┃┃╱┃╭╮╭┫┃╱┃┃╰╮╭╯┃╭━━╯┃┃┃┃
╭╯╰╯┃╰━━┫╰━╯┃╱┃┃╱┃┃┃╰┫╰━╯┃╱┃┃╱┃╰━━┳╯╰╯┃
╰━━━┻━━━┻━━━╯╱╰╯╱╰╯╰━┻━━━╯╱╰╯╱╰━━━┻━━━╯
```

---
Finally, you'll learn more about customizing this demonstration (if applicable)

## Customize Demonstration

In the event that you would like to re-run this demonstration and use different values: Edit the terraform.tfvars file in the `/existing` directory

---
Congratulations on completing this demonstration!
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>
