# airflow-kubernetes-eks

Use this repo to deploy a Kubernetes cluster on AWS EKS using Terraform ([ref](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks)) and then configure Airflow to run on Kubernetes ([ref](https://github.com/stwind/airflow-on-kubernetes)).


## Getting started

Open a terminal, navigate to the local directory where you want to clone the forked repo, and then execute the commands below.

```
# Clone the repo to your local machine
git clone git@github.com:schererjulie/airflow-kubernetes-eks.git

# Navigate to the cloned repository directory
cd airflow-kubernetes-eks

# Use the git remote command to add your forked repository as a remote
git remote add my-fork https://github.com/your-username/airflow-kubernetes-eks.git

# Verify that the forked repository has been added as a remote
git remote -v

# Sync your forked repo and retrieve the latest changes from the original repo
git fetch origin

# Merge changes in OG repo into your forked repo
git merge origin/main

# Push the changes to your forked repo
git push my-fork main
```

Your forked repository is now synced with this repo, and you can start making changes and pushing them to your forked repo.

------------------------------------------------------

## Creating an EKS cluster on AWS

If you don't have a Kubernetes cluster, you can follow the steps below to deploy an EKS cluster using Terraform. I'm using part of the set up from Hashicorp's tutorial [here](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks), which contains configuration to provision a VPC, security groups, and an EKS cluster.

* **_What is Elastic Kubernetes Service (EKS)?_** AWS's EKS is a managed Kubernetes service that makes it easy for you to deploy, manage, and scale containerized applications on Kubernetes.
* **_What is Kubernetes (K8S)?_** K8S is an open-source workload scheduler for automating deployment, scaling, and management of containerized applications.


### Prerequisites

You will need:

1. [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed locally
2. an AWS account and the AWS CLI installed and configured
3. [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) installed and configured
4. [kubectl](https://kubernetes.io/docs/tasks/tools/) installed

### TL;DR
* Configure AWS CLI
* Run `make terraform-up` to run Terraform and deploy the EKS cluster
* Run `make terraform-destroy` to destroy the resources and avoid incurring charges

### Configure AWS CLI

You can install the AWS CLI by following the instructions in the AWS documentation. Once the CLI is installed, you can configure it by running the `aws configure` command and providing your AWS access key ID and secret access key.
```
$ aws configure
AWS Access Key ID [****************XXXX]: ****************
AWS Secret Access Key [****************XXXX]: ****************
Default region name [us-east-1]: us-east-1
Default output format [None]: 
```

### Manual steps

**Run `make terraform-up`, or manually run the commands below**

_Note: This will take about 10 minutes to run._
```
# navigate to the Terraform directory
cd eks

# initialize Terraform
terraform init

# generate an execution plan
terraform plan

# apply the changes
terraform apply

# retrieve the cluster access credentials and configure `kubectl` to communicate with your cluster
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

# verify your cluster configuration
kubectl cluster-info
kubectl get nodes
```

### Check AWS

You can visit the [AWS management console](https://aws.amazon.com/console/) and search EKS, IAM, and VPC to check the EKS cluster, IAM roles, security groups, and VPC network, respectively. Make sure you're in the correct account and **us-east-1** region. If you want to see all the events that happened behind the scenes, you can always look at CloudTrail > Event history but that's probably gonna give a lot of extra details you don't really need.

Alternatively, you can use the commands below, assuming that you have the AWS CLI installed and configured with your AWS credentials.

```
# list all EKS clusters in your AWS account
aws eks list-clusters

# describe an EKS cluster
aws eks describe-cluster --name my-eks-cluster

# list all VPCs in your AWS account
aws ec2 describe-vpcs

# list all IAM roles in your AWS account
aws iam list-roles

# list all security groups in your AWS account
aws ec2 describe-security-groups

# list all policies in your AWS account
aws iam list-policies
```

### Destroy resources to avoid incurring extra charges

**Run `make terraform-down`, or manually run the commands below**
```
# navigate to the terraform dir
cd eks

# destroy the resources
terraform destroy
```

------------------------------------------------------

## Running Airflow on Kubernetes

### Prerequisites

You will need: 
- [Docker](https://docs.docker.com/get-docker/) installed
- [Helm](https://helm.sh/docs/intro/install/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed if you didn't already in the first part

### TL;DR
* Run `make airflow-init` to create namespace airflow
* Run `make airflow-up` to deploy Airflow on your Kubernetes cluster and then open [http://localhost:8080/](http://localhost:8080/) and enter admin for the username and password
* Run `make airflow-down` to delete airflow pods and namespace

**Manual steps**

```
# Create a Kubernetes namespace for your Airflow deployment
kubectl create namespace airflow
kubectl get namespaces

# Install the Airflow Helm chart
helm install airflow apache-airflow/airflow --namespace airflow

# Verify that Airflow is running
kubectl get pods -n airflow
helm ls -n airflow

# Create a Kubernetes service and port forwarding to the UI pod
kubectl port-forward -n airflow airflow-webserver 8080:8080
```

You can now access the Airflow UI by navigating to http://localhost:8080 in your web browser.


### Some other stuff ~ Helm chart

```
# get the Airflow Helm chart
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm search repo airflow

# save a copy of the values.yaml
helm show values apache-airflow/airflow > airflow/values.yaml

# configure Airflow's values.yaml file

# change executor from Celery (default) to Kubernetes 
executor: "KubernetesExecutor"
```

------------------------------------------------------

### References
- [Airflow on Kubernetes by stwind](https://github.com/stwind/airflow-on-kubernetes)
- [Airflow on Kubernetes by marclamberti](https://marclamberti.com/blog/airflow-on-kubernetes-get-started-in-10-mins/)
