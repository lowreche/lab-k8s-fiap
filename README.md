# lab-k8s-fiap
# Laboratório Prático FIAP: Como criar cluster local Kubernetes
Este laboratório permite a simulação de um cluster Kubernetes utilizando containers Ubuntu 24.04 como nós (Master e Worker) dentro de uma instância EC2.

# 📂 Estrutura de Arquivos
Dockerfile: Definição da imagem base com suporte a systemd.

create_kube_nodes.sh: Automação para provisionamento dos nós master1 e worker1.

fix_containerd.sh: Script para ajuste do runtime containerd para modo native.

# 📋 Pré-requisitos
Instância AWS EC2: Recomendado t3.large (2 vCPUs, 8GB RAM).

SO: Ubuntu 24.04 LTS.

# Armazenamento: Mínimo de 30GB (gp3).

# 🚀 Passo a Passo de Configuração

1. Preparação do Host (EC2)
Instale o motor Docker e configure as permissões:

sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io git
sudo usermod -aG docker ubuntu
newgrp docker

# 2. Build da Imagem Base

Clone o repositório e construa a imagem que servirá de base para os nós:

git clone https://github.com/luizreche/lab-k8s-fiap.git
cd lab-k8s-fiap

docker build -t Dockerfile .

# 3. Provisionamento dos Nós (Containers)

Execute o script para criar a rede isolada e os containers com os parâmetros de privilégio e mapeamento de cgroup:

chmod +x create_kube_nodes.sh
./create_kube_nodes.sh

# 4. Configuração do Master (Control Plane)

Acesse o master1 e inicialize o cluster:

docker exec -it master1 bash

# 4.1. Adicionar chaves e repositório do Kubernetes v1.30
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# 4.2. Instalar os pacotes
apt-get update
apt-get install -y containerd kubeadm kubelet kubectl

# 4.3. Configurar Containerd (Modo Native e Driver de Cgroup)
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/g' /etc/containerd/config.toml

# 4.4. Iniciar Runtime e Cluster
containerd > /var/log/containerd.log 2>&1 &
sleep 15

# 4.5. Criar arquivo de configuração para forçar driver cgroupfs (Obrigatório para Docker-in-Docker)
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

# 4.6. Inicializar o Cluster com a config de Cgroup
kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors=all

# 4.7. Configurar kubectl e Rede Calico
mkdir -p $HOME/.kube && cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
IMPORTANTE: Copie o comando kubeadm join gerado no final desta etapa.

# 5. Configuração do Data Plane (Worker)
Abra outro terminal no Host e acesse o worker1:

docker exec -it worker1 bash

# 5.1. Adicionar chaves e repositório do Kubernetes v1.30
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# 5.2. Instalar os pacotes
apt-get update
apt-get install -y containerd kubeadm kubelet kubectl
# 2. Configurar Containerd (Passo 4.3 do Master)
# 3. Iniciar o runtime:
containerd > /var/log/containerd.log 2>&1 &
sleep 15

# 4. Executar o JOIN (Use o seu token e hash gerados no Master)

# Adicione obrigatoriamente a flag --ignore-preflight-errors=all
kubeadm join 172.18.0.2:6443 --token <SEU_TOKEN> \
    --discovery-token-ca-cert-hash sha256:<SEU_HASH> \
    --ignore-preflight-errors=all
    
# ✅ Verificação de Sucesso
No Master, valide se os nós estão Ready:

# Verifique se os componentes do sistema estabilizaram (PID fixo)
ps -ef | grep kube

# Aguarde alguns minutos para o Calico subir as interfaces e rode:
kubectl get nodes

📝 Notas de Aula (Professor Luiz Reche)
Cgroup Driver: Forçamos o cgroupfs no arquivo kubeadm-config.yaml porque o driver systemd costuma falhar em ambientes aninhados (Docker-in-Docker).

Snapshotter Native: O Containerd precisa do modo native para gerenciar camadas de arquivos dentro do Docker sem conflitos de overlay.
