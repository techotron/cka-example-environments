#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/

apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni
apt-get autoremove -y
systemctl daemon-reload

# Disable swap
sed -i ‘/ swap / s/^\(.*\)$/#\1/g’ /etc/fstab

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF

exit 0
