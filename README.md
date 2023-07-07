**0 - Prerequisite to run Terraform codes**

 - terraform v1.5.2 
 - terragrunt v0.48.0 
 - git version 2.24.3

**1 - GCP Project Preparation**

 - A GCP project manually created via Google Cloud Console 
 - GCS Bucket to store remote statefiles
 - Service Account which has permissions to write new file to above Bucket and owner permissions to create new resources on project

**2 - Follow those steps to create the above resources**

*2.1 Login to Google Cloud Console --> Activate Cloud Shell*
```
CHARS_RANDOM="12345" ## Change to different characters so we can create unique Project ID on GCP
GROUNDZERO_PROJECT="lb-groundzero-$CHARS_RANDOM"
gcloud projects create $GROUNDZERO_PROJECT
```
*2.2 Link a billing account to this project*
```
Select this newly created project on GCP Console

Go to Billing Account page : https://console.cloud.google.com/billing/linkedaccount

Link a Billing Account
```
*2.3 Go back to Cloud Shell and execute the following commands to configure this new project**
```
gcloud config set project $GROUNDZERO_PROJECT

gcloud services enable cloudbilling.googleapis.com

gcloud services enable cloudresourcemanager.googleapis.com

gcloud services enable iam.googleapis.com

gcloud services enable artifactregistry.googleapis.com

gcloud services enable run.googleapis.com
```
 *2.4 Creating new GCS bucket used by Terraform to store Statefile ( make sure you change the ID to make it unique bucket name)**
```
gcloud storage buckets create gs://lb-congdev-tf-statefiles-1234 --project=$GROUNDZERO_PROJECT --location=europe-west1
```
*2.5 Creating New Service Account used by Terraform to provision resources on GCP**
```
gcloud iam service-accounts create tf-groundzero \

--description="SA used by Terraform to provision the next tasks" \

--display-name="TF-GroundZero"

TF_SA_EMAIL="tf-groundzero@lb-groundzero-$CHARS_RANDOM.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $GROUNDZERO_PROJECT --member="serviceAccount:$TF_SA_EMAIL" --role="roles/owner"
```
*Generate SA key and download to your development machine*
```
gcloud iam service-accounts keys create tf_sa_key.json \

--iam-account=$TF_SA_EMAIL
```

*2.6 Save this file as : "tf_sa_key.json"*

**3 Run terragrunt to provision required resources** 

Pull Terraform repo from github : ( Assumption: you have configured access using private key to your github account)

```
git clone git@github.com:congonline/lb-terraform.git
```
 
*3.1 To setup CongDev Infrastructure:*

*Declare the GCS Bucket created in step 2.4*
```
cd lb-terraform/assets/congdev
vi common_vars.yaml
Update : project_id: "lb-groundzero-12345"
Change "lb-tf-bucket" to the GCS Bucket name above: lb-congdev-tf-statefiles-1234
Change "ct_tf_statefile_proj" to the project ID above: lb-groundzero-12345
```

**4. How Terraform codes are designed and organised**

Directory: `blueprints`

```
This folder contains business logic and it describe all GCP services that will be used.
These codes can be shared and re-use for multiple environments.
```

Directory: `assets`
```
The main purpose of this folder is to declare different attribute for different environment. 
When terragrunt run inside those environment, it will pull code from `blueprints` and cache them locally.
To replicate and create new environment, you can copy folder `congdev` and change the attribute related to the environment that you would like to set up.
```
