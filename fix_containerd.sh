#!/bin/bash
set -e
echo "[1] Ajustando containerd para native snapshotter..."
sudo sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/g' /etc/containerd/config.toml
sudo systemctl restart containerd
echo "[OK] Snapshotter configurado!"
