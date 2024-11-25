![CrowdStrike](https://raw.github.com/CrowdStrike/Cloud-AWS/main/docs/img/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

# CrowdStrike Falcon Azure Storage Account Container Protection

> [!WARNING]
> This folder is being deprecated. There will be no more updates made to the contents of this folder. The solution has been moved and can be found here [azure-storage-account-container-protection](https://github.com/CrowdStrike/azure-storage-account-container-protection)

## Prerequisites
+ Have access to Azure w/ permissions to manage resources
+ Knowledge on creating Falcon API Keys

## Demonstration
This demonstration creates a new Azure Storage Account Container, implements Azure Storage Account Container Protection on that container, and then deploys an instance with several test scripts and sample files for testing the integration in a real environment.

Start the demo by following this documentation:

[Demo](demo)

## On-demand scanning
For scenarios where you either do not want to implement real-time protection, or where you are wanting to confirm the contents of a storage container before implementing protection, an on-demand scanning solution is provided as part of this integration.

This solution leverages the same APIs and logic that is implemented by the serverless handler that provides real-time protection.

The read more about this component, and use it by following this documentation:

[On Demand](on-demand).


## Deploying to an existing storage container
A helper routine is provided as part of this integration that assists with deploying protection to an existing storage container. This helper leverages Terraform, and can be started by executing the `existing.sh` script.

Start the demo by following this documentation:

[Existing](existing)
