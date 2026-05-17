#!/bin/bash

set -e

echo "======================================="
echo " Minikube Installation Starting "
echo "======================================="

# Update system
sudo dnf update -y

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

echo "======================================="
echo " Installing Docker "
echo "======================================="

# Amazon Linux 2023 already includes curl-minimal
sudo dnf install -y docker conntrack wget

# Enable Docker
sudo systemctl enable --now docker

# Add current user to docker group
sudo usermod -aG docker ec2-user || true

# Apply docker group without logout
newgrp docker <<EONG
echo "Docker group applied"
EONG

echo "======================================="
echo " Installing kubectl "
echo "======================================="

curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl

echo "======================================="
echo " Installing Minikube "
echo "======================================="

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube /usr/local/bin/minikube

rm -f minikube

echo "======================================="
echo " Removing Wrong KUBECONFIG "
echo "======================================="

unset KUBECONFIG

echo "======================================="
echo " Starting Minikube "
echo "======================================="

minikube start --driver=docker --force

echo "======================================="
echo " Enabling Dashboard "
echo "======================================="

minikube addons enable dashboard
minikube addons enable metrics-server

echo "Waiting for dashboard pods..."
sleep 30

echo "======================================="
echo " Verifying Dashboard "
echo "======================================="

kubectl get pods -n kubernetes-dashboard

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
