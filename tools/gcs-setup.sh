#!/bin/bash
# One-time setup of the place Subtle's releases are kept: a Google Cloud
# Storage bucket anyone can read (the website's download buttons fetch from it)
# and only you can write.
#
#   gcloud auth login            # first, if you aren't signed in
#   tools/gcs-setup.sh
#
# The project, bucket and region come from packaging/publish.env.
#
# Author: Alexius Academia
# Date: 2026-11-23
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source packaging/publish.env; set +a
: "${SUBTLE_GCS_PROJECT:?}" "${SUBTLE_GCS_BUCKET:?}" "${SUBTLE_GCS_REGION:?}"

echo "==> bucket gs://$SUBTLE_GCS_BUCKET in project $SUBTLE_GCS_PROJECT ($SUBTLE_GCS_REGION)"
if gcloud storage buckets describe "gs://$SUBTLE_GCS_BUCKET" --project "$SUBTLE_GCS_PROJECT" > /dev/null 2>&1; then
    echo "→ it's there already"
else
    gcloud storage buckets create "gs://$SUBTLE_GCS_BUCKET" --project "$SUBTLE_GCS_PROJECT" \
        --location "$SUBTLE_GCS_REGION" --uniform-bucket-level-access
fi
echo "→ letting everyone read it"
gcloud storage buckets add-iam-policy-binding "gs://$SUBTLE_GCS_BUCKET" \
    --member=allUsers --role=roles/storage.objectViewer > /dev/null
echo "→ counting its downloads (usage logs for stats.syncster.dev, prefix subtle)"
gcloud storage buckets update "gs://$SUBTLE_GCS_BUCKET" --log-bucket=syncster-usage-logs --log-object-prefix=subtle > /dev/null
echo "→ done: $SUBTLE_PUBLIC_BASE"
