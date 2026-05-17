#!/bin/bash

set -e

echo "=============================="
echo " Kubernetes Setup Starting "
echo "=============================="

# Disable swap permanently
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install required packages
dnf install -y iproute-tc curl

# Load kernel modules
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Kubernetes networking settings
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Disable SELinux
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Kubernetes Repository
KUBERNETES_VERSION=v1.29

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF

# CRI-O Repository
PROJECT_PATH=prerelease:/main

cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/$PROJECT_PATH/rpm/repodata/repomd.xml.key
EOF

# Install Kubernetes packages
dnf install -y cri-o kubelet kubeadm kubectl

# Enable and start services
systemctl daemon-reload
systemctl enable --now crio
systemctl enable --now kubelet

echo "=============================="
echo " Initializing Kubernetes "
echo "=============================="

# Initialize Kubernetes Cluster
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Mem
echo "=============================="
echo " Configuring kubectl "
echo "=============================="

# Configure kubectl for current user
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Set kubeconfig environment
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc

echo "=============================="
echo " Installing Flannel Network "
echo "=============================="

# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "=============================="
echo " Allow Scheduling on Master Node "
echo "=============================="

# For single node cluster
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "=============================="
echo " Cluster Status "
echo "=============================="

sleep 20

kubectl get nodes
kubectl get pods -A

echo "=============================="
echo " Kubernetes Installation Completed "
echo "=============================="
