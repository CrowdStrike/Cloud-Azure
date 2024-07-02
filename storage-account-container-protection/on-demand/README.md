![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)
[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

# On-demand Azure Cloud Storage Account container scanner

This example provides a stand-alone solution for scanning a Storage Account container before implementing protection.
While similar to the serverless function, this solution will only scan the bucket's _existing_ file contents.

> This example requires the `azure-storage-blob`, `azure-identity` and `crowdstrike-falconpy` (v0.8.7+) packages.

## Running the program

[Launch Cloud Shell](https://shell.azure.com)

Clone this repository by running the following commands

```shell
git clone https://github.com/CrowdStrike/Cloud-Azure.git
```


In order to run this solution, you will need:

+ The URL of the Azure Storage Account container
+ access to CrowdStrike API keys with the following scopes:
    | Service Collection | Scope |
    | :---- | :---- |
    | Quick Scan | __READ__, __WRITE__ |
    | Sample Uploads | __READ__, __WRITE__ |
+ `Storage Blob Data Contributor` permissions on the existing container

### Install requirements
Change to the storage-account-container-protection/on-demand directory and run the following command

```shell
python3 -m pip install -r requirements.txt
```

### Execution syntax

The following command will execute the solution against the bucket you specify using default options.

```shell
python3 quickscan_target.py -k CROWDSTRIKE_FALCON_API_KEY -s CROWDSTRIKE_FALCON_API_SECRET -t 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/<STORAGE_CONTAINER>/<PATH>'
```

A small command-line syntax help utility is available using the `-h` flag.

```shell
python3 quickscan_target.py -h
usage: Falcon Quick Scan [-h] [-l LOG_LEVEL] [-d CHECK_DELAY] [-b BATCH] -t TARGET -k KEY -s SECRET

options:
  -h, --help            show this help message and exit
  -l LOG_LEVEL, --log-level LOG_LEVEL
                        Default log level (DEBUG, WARN, INFO, ERROR)
  -d CHECK_DELAY, --check-delay CHECK_DELAY
                        Delay between checks for scan results
  -b BATCH, --batch BATCH
                        The number of files to include in a volume to scan.
  -t TARGET, --target TARGET
                        Target folder or container to scan. Value must start with 'https://' and have '.blob.core.windows.net' url suffix.
  -k KEY, --key KEY     CrowdStrike Falcon API KEY
  -s SECRET, --secret SECRET
                        CrowdStrike Falcon API SECRET
```

### Example output

```shell
2022-10-19 16:37:56,904 Quick Scan INFO Process startup complete, preparing to run scan
2022-10-19 16:37:59,962 Quick Scan INFO Assembling volumes from target container (test_sample_container) for submission
2022-10-19 16:38:02,078 Quick Scan INFO Uploaded README.md to 7f3efe17610c09e537c2494ad8d251ac300573f1c0f3ad4be500d650c9de5e7b
2022-10-19 16:38:03,934 Quick Scan INFO Uploaded README.md to 5252d7c5b99506a6a7b1fe8819485ca9847f7528476a4bb9f5d8b869a8c8726c
2022-10-19 16:38:06,563 Quick Scan INFO Uploaded youtube.png to 47af72b75c35839a381bf91f03f4d3b87eb4283af58ff4809e137eff2f06cb40
2022-10-19 16:38:08,479 Quick Scan INFO Uploaded .gitignore to ce2de08a3889bf39fcd4cdb43d9f83197fcf17ab5c5707b1c4490e9b6cede8f4
...
...
2022-10-19 16:38:50,466 Quick Scan INFO Unscannable file container/gke-implementation-guide.md: verdict unknown
2022-10-19 16:38:50,467 Quick Scan INFO Unscannable file container/pull-secret-override.md: verdict unknown
2022-10-19 16:38:50,467 Quick Scan INFO Verdict for safe1.bin: no specific threat
2022-10-19 16:38:50,467 Quick Scan INFO Unscannable file test.pdf: verdict unknown
...
...
2022-10-19 16:38:50,467 Quick Scan INFO Removing artifacts from Sandbox
2022-10-19 16:39:55,389 Quick Scan INFO Scan completed
```
