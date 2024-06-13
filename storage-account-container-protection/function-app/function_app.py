"""CrowdStrike Azure Storage Account Container Protection with QuickScan.

Based on the work of @jshcodes w/ s3-bucket-protection & @carlos.matos w/ cloud-storage-protection

Creation date: 05.27.24 - gax.theodorio@CrowdStrike
"""

import io
import os
import time
import json
import logging
import azure.functions as func
import azurefunctions.extensions.bindings.blob as blob
from falconpy import OAuth2, SampleUploads, QuickScan

app = func.FunctionApp()

# Maximum file size for scan (35mb)
MAX_FILE_SIZE = 36700160

# Mitigate threats?
MITIGATE = bool(json.loads(os.environ.get("MITIGATE_THREATS", "TRUE").lower()))

# Base URL
BASE_URL = os.environ.get("BASE_URL", "https://api.crowdstrike.com")

# Grab our Falcon API creds from the environment if they exist
try:
    client_id = os.environ["FALCON_CLIENT_ID"]
except KeyError:
    raise SystemExit("FALCON_CLIENT_ID environment variable not set")

try:
    client_secret = os.environ["FALCON_CLIENT_SECRET"]
except KeyError:
    raise SystemExit("FALCON_CLIENT_SECRET environment variable not set")

# Authenticate to the CrowdStrike Falcon API
auth = OAuth2(
    creds={"client_id": client_id, "client_secret": client_secret}, base_url=BASE_URL
)

# Connect to the Samples Sandbox API
Samples = SampleUploads(auth_object=auth)
# Connect to the Quick Scan API
Scanner = QuickScan(auth_object=auth)


@app.blob_trigger(
    arg_name="client",
    path=os.environ.get("quick_scan_container_name", ""),
    connection="azurequickscan_STORAGE",
)
def container_protection(client: blob.BlobClient):

    logging.info(f"ClientID: {client_id}... ClientSecret: {client_secret}")

    blob_properties = client.get_blob_properties()
    file_size = blob_properties["size"]
    file_name = blob_properties["name"]
    container = blob_properties["container"]

    if file_size < MAX_FILE_SIZE:
        # Get the blob file
        file_stream = io.BytesIO(client.download_blob().read())
        # Upload the file to the CrowdStrike Falcon Sandbox
        response = Samples.upload_sample(
            file_name=file_name,
            file_data=file_stream,
        )
        if response["status_code"] > 201:
            raise SystemExit(
                f"Error uploading object {file_name} from container {container} to Falcon Intelligence Sandbox. "
                "Make sure your API key has the Sample Uploads permission."
            )
        else:
            logging.info("File uploaded to CrowdStrike Falcon Sandbox.")

        # Quick Scan
        try:
            # Uploaded file unique identifier
            upload_sha = response["body"]["resources"][0]["sha256"]
            # Scan request ID, generated when the request for the scan is made
            scan_id = Scanner.scan_samples(body={"samples": [upload_sha]})["body"][
                "resources"
            ][0]
            scanning = True
            # Loop until we get a result or the function times out
            while scanning:
                # Retrieve our scan using our scan ID
                scan_results = Scanner.get_scans(ids=scan_id)
                try:
                    if scan_results["body"]["resources"][0]["status"] == "done":
                        # Scan is complete, retrieve our results (there will be only one)
                        result = scan_results["body"]["resources"][0]["samples"][0]
                        # and break out of the loop
                        scanning = False
                    else:
                        # Not done yet, sleep for a bit
                        time.sleep(3)
                except IndexError:
                    # Results aren't populated yet, skip
                    pass
            if result["sha256"] == upload_sha:
                if "no specific threat" in result["verdict"]:
                    # File is clean
                    scan_msg = f"No threat found in {file_name}"
                    logging.info(scan_msg)
                elif "unknown" in result["verdict"]:
                    if "error" in result:
                        # Error occurred
                        scan_msg = f"Scan error for {file_name}: {result['error']}"
                        logging.info(scan_msg)
                    else:
                        # Undetermined scan failure
                        scan_msg = f"Unable to scan {file_name}"
                        logging.info(scan_msg)
                elif "malware" in result["verdict"]:
                    # Mitigation would trigger from here
                    scan_msg = f"Verdict for {file_name}: {result['verdict']}"
                    logging.warning(scan_msg)
                    threat_removed = False
                    if MITIGATE:
                        # Remove the threat
                        try:
                            client.delete_blob()
                            threat_removed = True
                        except Exception as err:
                            logging.warning(
                                "Unable to remove threat %s from bucket %s",
                                file_name,
                                container,
                            )
                            print(f"{err}")
                    else:
                        # Mitigation is disabled. Complain about this in the logging.
                        logging.warning(
                            "Threat discovered (%s). Mitigation disabled, threat persists in %s bucket.",
                            file_name,
                            container,
                        )

                    if threat_removed:
                        logging.info(
                            "Threat %s removed from bucket %s", file_name, container
                        )
                else:
                    # Unrecognized response
                    scan_msg = f"Unrecognized response ({result['verdict']}) received from API for {file_name}."
                    logging.info(scan_msg)

            # Clean up the artifact in the sandbox
            response = Samples.delete_sample(ids=upload_sha)
            if response["status_code"] > 201:
                logging.warning(
                    f"Could not remove sample {file_name} from sandbox.",
                )
            else:
                logging.info(f"Sample {file_name} removed from sandbox.")

        except Exception as err:
            logging.error(err)
            print(
                f"Error getting object {file_name} from bucket {container}. "
                "Make sure they exist and your bucket is in the same region as this function."
            )
            raise err

    else:
        msg = f"File ({file_name}) exceeds maximum file scan size ({MAX_FILE_SIZE} bytes), skipped."
        logging.warning(msg)
