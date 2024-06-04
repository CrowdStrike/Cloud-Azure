#!/bin/bash
echo "Uploading test files, please wait..."
# shellcheck disable=SC2045
for i in $(ls TESTS_DIR); do
    echo "Uploading $i to STORAGE_CONTAINER..."
    az storage blob upload --account-name STORAGE_ACCOUNT --container-name STORAGE_CONTAINER --overwrite --name "$i" --file TESTS_DIR/"$i" --account-key STORAGE_ACCOUNT_KEY >/dev/null 2>&1
done
echo "Upload complete. Check App insights logs or use the get-findings command for scan results."
