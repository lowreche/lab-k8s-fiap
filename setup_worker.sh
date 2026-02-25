#!/bin/bash
# setup_worker.sh

echo "[+] 1. Instalando Repositórios e Binários..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update && apt-get install -y containerd kubeadm kubelet kubectl

echo "[+] 2. Configurando Containerd..."
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/g' /etc/containerd/config.toml
containerd > /var/log/containerd.log 2>&1 &
sleep 10

echo "=========================================================="
echo "WORKER PRONTO! Agora rode o comando 'kubeadm join' do Master."
echo "Lembre-se de adicionar: --ignore-preflight-errors=all"
echo "=========================================================="
