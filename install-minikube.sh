#!/bin/bash
sudo yum install -y docker
sudo systemctl start docker.service
sudo systemctl enable docker.service

curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod 777 ./kubectl
sudo mv ./kubectl /usr/local/bin/

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod 777 minikube
sudo mv minikube /usr/local/bin/

sudo  minikube start --force
 minikube addons enable dashboard 

 kubectl proxy --address='0.0.0.0' --disable-filter=true

 ## try the url in the browser:  http://<EC2-Public-IP>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/   
 ###  ## try the url in the browser:  http://18.176.215.11:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/   


sudo kubectl get pods -A
sudo kubectl get nodes
