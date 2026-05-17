#!/bin/bash

set -e

echo "======================================="
echo " Kubernetes Master Setup Starting "
echo "======================================="

# Disable swap
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

# Kubernetes repo
KUBERNETES_VERSION=v1.29

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF

# CRI-O repo
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

echo "======================================="
echo " Initializing Kubernetes Cluster "
echo "======================================="

# Initialize cluster
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Mem

echo "======================================="
echo " Configuring kubectl "
echo "======================================="

mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc

echo "======================================="
echo " Installing Flannel Network "
echo "======================================="

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

sleep 30

echo "======================================="
echo " Allow Scheduling on Master Node "
echo "======================================="

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "======================================="
echo " Installing Kubernetes Dashboard "
echo "======================================="

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

sleep 20

echo "======================================="
echo " Creating Dashboard Admin User "
echo "======================================="

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

echo "======================================="
echo " Dashboard Token "
echo "======================================="

kubectl -n kubernetes-dashboard create token admin-user

echo ""
echo "======================================="
echo " Dashboard Access "
echo "======================================="
echo ""

PUBLIC_IP=$(curl -s ifconfig.me)

echo "Run this command in another terminal:"
echo ""
echo "kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443 --address 0.0.0.0"
echo ""
echo "Then open:"
echo ""
echo "https://$PUBLIC_IP:8443"
echo ""

echo "======================================="
echo " Worker Node Join Command "
echo "======================================="

kubeadm token create --print-join-command

echo ""
echo "======================================="
echo " Cluster Status "
echo "======================================="

kubectl get nodes
kubectl get pods -A

echo ""
echo "======================================="
echo " Kubernetes Master Setup Completed "
echo "======================================="
