#!/bin/bash

set -e

echo "======================================="
echo " Kubernetes Worker Setup Starting "
echo "======================================="

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install required package
dnf install -y iproute-tc

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

echo "======================================="
echo " Installing Kubernetes Packages "
echo "======================================="

dnf install -y cri-o kubelet kubeadm kubectl

# Enable services
systemctl daemon-reload
systemctl enable --now crio
systemctl enable --now kubelet

echo ""
echo "======================================="
echo " Worker Node Installation Completed "
echo "======================================="
echo ""
echo "Run the join command from master node:"
echo ""
echo "kubeadm join <MASTER-IP>:6443 --token <TOKEN> \\"
echo "--discovery-token-ca-cert-hash sha256:<HASH>"
echo ""
