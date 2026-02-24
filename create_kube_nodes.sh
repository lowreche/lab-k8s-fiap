#!/bin/bash
set -e

echo "[+] Limpando ambiente anterior..."
docker rm -f master1 worker1 2>/dev/null || true
docker network rm kube-net 2>/dev/null || true

echo "[+] Criando rede do cluster (172.18.0.0/16)..."
docker network create --subnet=172.18.0.0/16 kube-net

echo "[+] Criando Master1 (IP: 172.18.0.2)..."
docker run -d --privileged \
  --name master1 --hostname master1 \
  --network kube-net --ip 172.18.0.2 \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  kube-ubuntu:24

echo "[+] Criando Worker1 (IP: 172.18.0.3)..."
docker run -d --privileged \
  --name worker1 --hostname worker1 \
  --network kube-net --ip 172.18.0.3 \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  kube-ubuntu:24

echo ""
echo "=========================================="
echo "        NODES CRIADOS COM SUCESSO         "
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
