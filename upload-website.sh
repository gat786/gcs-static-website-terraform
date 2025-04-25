#!/bin/bash
BUCKET_NAME=gats-dev-static-content-bucket

# upload everything in website/ to BUCKET_NAME
gcloud storage cp -r website/* gs://$BUCKET_NAME/
