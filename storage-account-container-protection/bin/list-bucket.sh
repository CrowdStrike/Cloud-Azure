#!/bin/bash
az storage blob list --account-name STORAGE_ACCOUNT --container-name STORAGE_CONTAINER --account-key STORAGE_ACCOUNT_KEY | jq .[].name
