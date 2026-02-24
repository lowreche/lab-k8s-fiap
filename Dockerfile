FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y systemd iptables iproute2 curl vim sudo ssh net-tools \
    apt-transport-https ca-certificates gnupg lsb-release && \
    apt-get clean

# Essencial para rodar systemd dentro do container
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/sbin/init"]
