
# Description

This terraform project creates a EKS cluster , installs victoriametrics, prometheus and push the prometheus data from prometheus to victoriametrics


# Setup


1. Set up AWS credentiatls using aws configure
2. Setup terraform 0.12
3. run 
```sh
terraform init
terraform plan -var 'eks_cluster_name=<eks_name>' -var 'region=<region>'
terraform apply -var 'eks_cluster_name=<eks_name>' -var 'region=<region>'
```


# Validation 
1. Setup kubectl config to eks cluster
```sh
aws eks --region us-east-1 update-kubeconfig --name <eks_name>
```
2. Check if nodes and pods are present 
```sh
kubectl get nodes
kubectl get pods -n prometheus
```
3. Validate Prometheus
```sh
kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090
```
Access http://localhost:9090

4. Validate if Prometheus data is ingested to victoria metrics
```sh
export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=vmselect" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace prometheus port-forward $POD_NAME 8481

```
GET http://localhost:8481/select/0/prometheus/api/v1/labels
