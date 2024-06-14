# pylint: disable=W1401
# flake8: noqa
"""Scan an Azure Storage Account container with the CrowdStrike Quick Scan API.

  _______ ___ ___ ___ _______ ___ ___    _______ _______ _______ ______     _______ _______ ___
 |   _   |   Y   |   |   _   |   Y   )  |   _   |   _   |   _   |   _  \   |   _   |   _   |   |
 |.  |   |.  |   |.  |.  1___|.  1  /   |   1___|.  1___|.  1   |.  |   |  |.  1   |.  1   |.  |
 |.  |   |.  |   |.  |.  |___|.  _  \   |____   |.  |___|.  _   |.  |   |  |.  _   |.  ____|.  |
 |:  1   |:  1   |:  |:  1   |:  |   \  |:  1   |:  1   |:  |   |:  |   |  |:  |   |:  |   |:  |
 |::..   |::.. . |::.|::.. . |::.| .  ) |::.. . |::.. . |::.|:. |::.|   |  |::.|:. |::.|   |::.|
 `----|:.`-------`---`-------`--- ---'  `-------`-------`--- ---`--- ---'  `--- ---`---'   `---'
      `--'

Scans an Azure Storage Account container using the CrowdStrike Falcon Quick Scan and Sample Uploads APIs.

Created // 06.12.24: gtheodorio@CrowdStrike
Based on // jshcodes@CrowdStrike - S3 Quick Scan Script

===== NOTES REGARDING THIS SOLUTION ============================================================

A VOLUME is a collection of files that are uploaded and then scanned as a singular batch.

The container contents are inventoried, and then the contents are downloaded to local memory and
uploaded to the Sandbox API in a linear fashion. This method does NOT store the files on the local
file system. Due to the nature of this solution, the method is heavily impacted by data transfer
speeds. Recommended deployment pattern involves running in Azure within a container, a virtual machine instance
or as a function app. Scans the entire container whether you like it or not. You must specify a
target that includes the storage account name and container name in order to perform a scan.

The log file rotates because cool kids don't leave messes on other people's file systems.

This solution is dependant upon Azure's Blob Storage client library, and CrowdStrike FalconPy >= v0.8.7.
    python3 -m pip install azure-storage-blob azure-identity crowdstrike-falconpy

"""
# pylint: disable=E0401,R0903
#
import io
import os

# import json
import time
import argparse
import logging
from logging.handlers import RotatingFileHandler

# !!! Requires FalconPy v0.8.7+ !!!
# Authorization, Sample Uploads and QuickScan Service Classes
from falconpy import OAuth2, SampleUploads, QuickScan

# import azure libraries
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(
    logging.WARNING
)


class Analysis:
    """Class to hold our analysis and status."""

    def __init__(self):
        self.uploaded = []
        self.files = []
        self.scanning = True
        # Dynamically create our payload using the contents of our uploaded list
        self.payload = lambda: {"samples": list(dict.fromkeys(self.uploaded))}


class Configuration:  # pylint: disable=R0902
    """Class to hold our running configuration."""

    def __init__(self, args):
        self.log_level = logging.INFO
        if args.log_level:
            if args.log_level.upper() in "DEBUG,WARN,ERROR".split(","):
                if args.log_level.upper() == "DEBUG":
                    self.log_level = logging.DEBUG
                elif args.log_level.upper() == "WARN":
                    self.log_level = logging.WARN
                elif args.log_level.upper() == "ERROR":
                    self.log_level = logging.ERROR

        self.batch = 1000
        if args.batch:
            self.batch = int(args.batch)
        self.scan_delay = 3
        if args.check_delay:
            try:
                self.scan_delay = int(args.check_delay)
            except ValueError:
                # They gave us garbage, ignore it
                pass
        # Will stop processing if you give us a bucket and no project
        # Target directory or container to be scanned
        if "blob.core.windows" in args.target and "https://" in args.target:
            self.target = args.target
            self.target_prefix = "/".join(self.target.split("/")[4:])
            self.container_name = self.target.split("/")[3]
            self.container = True
            # parse storage account value from target
            self.storage_account = self.target.split("/")[2].split(".")[0]
        else:
            self.container = False
        # CrowdStrike API credentials
        self.falcon_client_id = args.key
        self.falcon_client_secret = args.secret


def submit_scan(incoming_analyzer: Analysis):
    """Submit the collected file batch for analysis."""
    scanned = Scanner.scan_samples(body=incoming_analyzer.payload())
    if scanned["status_code"] < 300:
        # Submit our volume for analysis and grab the id of our scan submission
        scan_id = scanned["body"]["resources"][0]
        # Inform the user of our progress
        logger.info("Scan %s submitted for analysis", scan_id)
        # Retrieve our scan results from the API and report them
        report_results(
            scan_uploaded_samples(incoming_analyzer, scan_id), incoming_analyzer
        )
    else:
        if "errors" in scanned["body"]:
            logger.warning(
                "%s. Unable to submit volume for scan.",
                scanned["body"]["errors"][0]["message"],
            )
        else:
            # Rate limit only
            logger.warning("Rate limit exceeded.")
    # Clean up our uploaded files from out of the API
    clean_up_artifacts(incoming_analyzer)


def upload_bucket_samples():
    """Retrieve keys from a container and then uploads them to the Sandbox API."""
    # Connect to our target storage account
    account_url = f"https://{Config.storage_account}.blob.core.windows.net"
    default_credential = DefaultAzureCredential()
    blob_service_client = BlobServiceClient(account_url, credential=default_credential)
    # Connect to our target container

    try:
        container = blob_service_client.get_container_client(
            container=Config.container_name
        )
    except Exception as err:
        logger.error("Unable to connect to container %s. %s", Config.target_dir, err)
        raise SystemExit(
            "Unable to connect to container %s. %s" % (Config.container_name, err)
        )
    # Retrieve a list of all objects in the container
    summaries = container.list_blobs(name_starts_with=Config.target_prefix)
    logger.info(summaries)
    # Inform the user as this may take a while
    logger.info(
        "Assembling volumes from target container (%s) for submission",
        Config.container_name,
    )
    # # Loop through our list of files, downloading each to memory then upload them to the Sandbox
    analyzer = None
    analyzed = []
    for item in summaries:
        if not analyzer:
            analyzer = Analysis()
        # Grab the file name
        filename = os.path.basename(item.name)
        logger.info(filename)
        # Upload the file to the CrowdStrike Falcon Sandbox
        response = Samples.upload_sample(
            file_name=filename,
            file_data=io.BytesIO(
                container.get_blob_client(item).download_blob().readall()
            ),
        )
        # Retrieve our uploaded file SHA256 identifier
        if len(response["body"]["errors"]) == 0:
            sha = response["body"]["resources"][0]["sha256"]
            # Add this SHA256 to the upload payload element
            analyzer.uploaded.append(sha)
            # Track the upload so we recognize the file when we're done
            analyzer.files.append([filename, item.name, sha])
            # Inform the user of our progress
            logger.info("Uploaded %s to %s", filename, sha)
            if len(analyzer.uploaded) == Config.batch:
                analyzed.append(analyzer)
                submit_scan(analyzer)
                analyzer = None
        else:
            error_messages = [error["message"] for error in response["body"]["errors"]]
            logger.error(f"Error(s) received from sandbox: {error_messages}")

    analyzed.append(analyzer)
    submit_scan(analyzer)


def scan_uploaded_samples(incoming_analyzer: Analysis, scan_id: str) -> dict:
    """Retrieve a scan using the ID of the scan provided by the scan submission."""
    while incoming_analyzer.scanning:
        # Retrieve the scan results
        scan_results = Scanner.get_scans(ids=scan_id)
        try:
            if scan_results["body"]["resources"][0]["status"] == "done":
                # Scan is complete, retrieve our results
                results = scan_results["body"]["resources"][0]["samples"]
                # and break out of the loop
                incoming_analyzer.scanning = False
            else:
                # Not done yet, sleep for a bit
                time.sleep(Config.scan_delay)
        except IndexError:
            # Results aren't populated yet, skip
            pass

    return results


def report_results(results: dict, incoming_analyzer: Analysis):
    """Retrieve the scan results for the submitted scan."""
    # Loop thru our results, compare to our upload and return the verdict
    for result in results:
        for item in incoming_analyzer.files:
            if result["sha256"] == item[2]:
                if "no specific threat" in result["verdict"]:
                    # File is clean
                    logger.info("Verdict for %s: %s", item[1], result["verdict"])
                else:
                    if "error" in result:
                        # Unscannable
                        logger.info(
                            "Unscannable file %s: verdict %s",
                            item[1],
                            result["verdict"],
                        )
                    else:
                        # Mitigation would trigger from here
                        logger.warning("Verdict for %s: %s", item[1], result["verdict"])


def clean_up_artifacts(incoming_analyzer: Analysis):
    """Remove uploaded files from the Sandbox."""
    logger.info("Removing artifacts from Sandbox")
    for item in incoming_analyzer.uploaded:
        # Perform the delete
        response = Samples.delete_sample(ids=item)
        if response["status_code"] > 201:
            # File was not removed, log the failure
            logger.warning("Failed to delete %s", item)
        else:
            logger.debug("Deleted %s", item)
    logger.debug("Artifact cleanup complete")


def parse_command_line():
    """Parse any inbound command line arguments and set defaults."""
    parser = argparse.ArgumentParser("Falcon Quick Scan")
    parser.add_argument(
        "-l",
        "--log-level",
        dest="log_level",
        help="Default log level (DEBUG, WARN, INFO, ERROR)",
        required=False,
    )
    parser.add_argument(
        "-d",
        "--check-delay",
        dest="check_delay",
        help="Delay between checks for scan results",
        required=False,
    )
    parser.add_argument(
        "-b",
        "--batch",
        dest="batch",
        help="The number of files to include in a volume to scan.",
        required=False,
    )
    parser.add_argument(
        "-t",
        "--target",
        dest="target",
        help="Target folder or container to scan. Value must start with 'https://' and have '.blob.core.windows.net' url suffix.",
        required=True,
    )
    parser.add_argument(
        "-k",
        "--key",
        dest="key",
        help="CrowdStrike Falcon API KEY",
        required=True,
    )
    parser.add_argument(
        "-s",
        "--secret",
        dest="secret",
        help="CrowdStrike Falcon API SECRET",
        required=True,
    )

    return parser.parse_args()


def load_api_config():
    """Return an instance of the authentication class using our provided credentials."""
    return OAuth2(
        client_id=Config.falcon_client_id, client_secret=Config.falcon_client_secret
    )


def enable_logging():
    """Configure logging."""
    logging.basicConfig(
        level=Config.log_level, format="%(asctime)s %(name)s %(levelname)s %(message)s"
    )
    # Create our logger
    log = logging.getLogger("Quick Scan")
    # Rotate log file handler
    rfh = RotatingFileHandler("falcon_quick_scan.log", maxBytes=20971520, backupCount=5)
    # Log file output format
    f_format = logging.Formatter("%(asctime)s %(name)s %(levelname)s %(message)s")
    # Set the log file output level
    rfh.setLevel(Config.log_level)
    # Add our log file formatter to the log file handler
    rfh.setFormatter(f_format)
    # Add our log file handler to our logger
    log.addHandler(rfh)

    return log


if __name__ == "__main__":
    # Parse the inbound command line parameters and setup our running Config object
    Config = Configuration(parse_command_line())
    # Activate logging
    logger = enable_logging()
    # Grab our authentication object
    auth = load_api_config()
    # Connect to the Samples Sandbox API
    Samples = SampleUploads(auth_object=auth)
    # Connect to the Quick Scan API
    Scanner = QuickScan(auth_object=auth)
    # Create our analysis object
    # Analyzer = Analysis()
    # Log that startup is done
    logger.info("Process startup complete, preparing to run scan")
    # Upload our samples to the Sandbox
    if Config.container:
        # Azure container
        upload_bucket_samples()
    else:
        NOT_A_BUCKET = "Invalid storage container url specified. Please include the full url in your target value. Value should be in the format 'https://<storage_account_name>.blob.core.windows.net/<storage_container>/<path>'"
        raise SystemExit(NOT_A_BUCKET)
    # We're done, let everyone know
    logger.info("Scan completed")
