PROJECT_NAME=airflow
include .env

.PHONY: terraform-up
terraform-up:
	cd eks && \
	terraform init -upgrade && \
	terraform apply -auto-approve
	aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
	kubectl cluster-info
	kubectl get nodes -o wide
	echo "CLUSTER_NAME=$(shell kubectl config current-context)" >> .env

.PHONY: terraform-destroy
terraform-destroy:
	cd eks && \
	terraform destroy -auto-approve


.PHONY: airflow-init
airflow-init:
	mkdir -p airflow/dags airflow/plugins airflow/logs
	kubectl create namespace airflow
	helm install airflow apache-airflow/airflow --values airflow/values.yaml --namespace airflow
	echo "FERNET_KEY='$(shell kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)'" >> .env
	kubectl get pods -n airflow

.PHONY: airflow-up
airflow-up:
	# kubectl get pods -n airflow
	kubectl port-forward -n airflow $(shell kubectl get pods -n airflow -o name --field-selector=status.phase==Running | grep ^pod/airflow-webserver | cut -d "/" -f2) 8080:8080 --context ${CLUSTER_NAME}

.PHONY: airflow-down
airflow-down:
	kubectl -n airflow delete pod,svc --all
	kubectl delete -n airflow
	kubectl get pods -n airflow
