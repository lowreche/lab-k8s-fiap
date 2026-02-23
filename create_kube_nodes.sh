#!/bin/bash
set -e

# Cria a rede do cluster
docker network create kube-net || true

MASTERS=2
WORKERS=2

echo "[+] Criando masters..."
for i in $(seq 1 $MASTERS); do
    docker run -d --privileged --name master$i --hostname master$i \
      --cgroupns=host --network kube-net \
      -v /sys/fs/cgroup:/sys/fs/cgroup:rw kube-ubuntu:24
done

echo "[+] Criando workers..."
for i in $(seq 1 $WORKERS); do
    docker run -d --privileged --name worker$i --hostname worker$i \
      --cgroupns=host --network kube-net \
      -v /sys/fs/cgroup:/sys/fs/cgroup:rw kube-ubuntu:24
done

echo "NODES CRIADOS COM SUCESSO!"
docker ps --format "table {{.Names}}\t{{.Status}}"
