#!/bin/sh
az monitor app-insights query --app APP_INSIGHTS_APP_ID --analytics-query "traces | where message has \"Threat\" or message has \"Mitigate\" | project message" --output jsonc
