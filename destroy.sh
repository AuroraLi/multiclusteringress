#!/bin/bash
export PROJECT_ID=$(gcloud config get-value project)
gcloud builds submit --config destroy.yaml