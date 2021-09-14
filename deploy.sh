#!/bin/bash
export PROJECT_ID=$(gcloud config get-value project)
gcloud services enable --project ${PROJECT_ID?} \
    cloudresourcemanager.googleapis.com \
    multiclusteringress.googleapis.com \
    gkehub.googleapis.com \
    container.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com \
    cloudbuild.googleapis.com \
    stackdriver.googleapis.com \
    multiclusterservicediscovery.googleapis.com \
    dns.googleapis.com \
    trafficdirector.googleapis.com
CLOUDBUILD_SA=$(gcloud projects describe ${PROJECT_ID?} --format='value(projectNumber)')@cloudbuild.gserviceaccount.com 
gcloud projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${CLOUDBUILD_SA?} --role roles/owner
gcloud projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${CLOUDBUILD_SA?} --role roles/iam.serviceAccountTokenCreator
gcloud builds submit --config cloudbuild.yaml