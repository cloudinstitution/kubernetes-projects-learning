#!/bin/bash

set -e

echo "======================================="
echo " Minikube Installation Starting "
echo "======================================="

# Update system
dnf update -y

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "======================================="
echo " Installing Docker "
echo "======================================="

# Install Docker
dnf install -y docker conntrack curl wget

# Enable Docker
systemctl enable --now docker

# Add ec2-user to docker group
usermod -aG docker ec2-user || true

echo "======================================="
echo " Installing kubectl "
echo "======================================="

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl

echo "======================================="
echo " Installing Minikube "
echo "======================================="

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

install minikube /usr/local/bin/minikube

rm -f minikube

echo "======================================="
echo " Starting Minikube "
echo "======================================="

minikube start --driver=docker --force

echo "======================================="
echo " Enabling Dashboard "
echo "======================================="

minikube addons enable dashboard
minikube addons enable metrics-server

echo "======================================="
echo " Starting Dashboard Port Forward "
echo "======================================="

nohup kubectl port-forward --address 0.0.0.0 -n kubernetes-dashboard service/kubernetes-dashboard 8443:80 > /tmp/dashboard-portforward.log 2>&1 &

sleep 10

PUBLIC_IP=$(curl -s ifconfig.me)

echo ""
echo "======================================="
echo " Minikube Dashboard URL "
echo "======================================="
echo ""

echo "http://$PUBLIC_IP:8443"
echo ""

echo "======================================="
echo " Cluster Status "
echo "======================================="

kubectl get nodes
kubectl get pods -A

echo ""
echo "======================================="
echo " Minikube Installation Completed "
echo "======================================="



# #!/bin/bash
# sudo yum install -y docker
# sudo systemctl start docker.service
# sudo systemctl enable docker.service

# curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod 777 ./kubectl
# sudo mv ./kubectl /usr/local/bin/

# curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# chmod 777 minikube
# sudo mv minikube /usr/local/bin/

# sudo  minikube start --force
#  minikube addons enable dashboard 

#  kubectl proxy --address='0.0.0.0' --disable-filter=true

#  ## try the url in the browser:  http://<EC2-Public-IP>:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/   
#  ###  ## try the url in the browser:  http://18.176.215.11:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/   


# sudo kubectl get pods -A
# sudo kubectl get nodes
