#!/bin/bash
# setup_master.sh

echo "[+] 1. Configurando Repositórios K8s..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

echo "[+] 2. Instalando Binários..."
apt-get update && apt-get install -y containerd kubeadm kubelet kubectl

echo "[+] 3. Configurando Containerd (Native Snapshotter)..."
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/g' /etc/containerd/config.toml
containerd > /var/log/containerd.log 2>&1 &
sleep 10

echo "[+] 4. Criando arquivo de configuração Kubeadm..."
cat <<EOF > kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.30.0
networking:
  podSubnet: "10.244.0.0/16"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: cgroupfs
EOF

echo "[+] 5. Inicializando o Cluster..."
kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors=all

echo "[+] 6. Configurando Kubeconfig e Rede (Calico)..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
curl -L https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml -o calico.yaml
sed -i '/- name: CLUSTER_TYPE/i \            - name: IP_AUTODETECTION_METHOD\n              value: "interface=eth0"' calico.yaml
kubectl apply -f calico.yaml

echo "=========================================================="
echo "MASTER CONFIGURADO COM SUCESSO!"
echo "Copie o comando 'kubeadm join' abaixo para os Workers."
echo "=========================================================="
