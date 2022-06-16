# Cluster 2 Tasks

## Create a cluster
Using cluster2,  spin up the 3 servers and create a 1 master, 2 worker node cluster. Make sure the cluster version is v1.21.0


The script does the following for convenience:

- Disable swap
- Add apt gpg key
- Add kubernetes repo list
- Apt-get update

<details>
  <summary>Click to show answer!</summary>
```bash
apt-get install -y docker.io kubeadm=1.21.0-00 kubelet=1.21.00-00 kubectl=1.21.0-00
apt-mark hold kubelet kubeadm kubectl
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload && systemctl restart docker
systemctl enable docker
systemctl enable kubelet && systemctl start kubelet
kubeadm init –kubernetes-version=1.21.0 –apiserver-advertise-address=192.168.57.101 –pod-network-cidr=10.244.0.0/16
kubeadm token create –print-join-command (it’s also in the output of the previous command)
```
</details>
