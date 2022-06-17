# Cluster 2 Tasks

## 1. Create a new cluster
Spin up cluster2 and install a kubernetes cluster with 1 control plane node (`cluster2-master1`) with 2 worker nodes (`cluster2-worker1/2`) using `kubeadm`. Make sure the cluster version is v1.21.0

<br><hr>
<details>
  <summary>Click to show answer!</summary>
  <br><hr>
    <pre>
        <code>
        apt-get install -y docker.io kubeadm=1.21.0-00 kubelet=1.21.00-00 kubectl=1.21.0-00
        apt-mark hold kubelet kubeadm kubectl
        mkdir -p /etc/systemd/system/docker.service.d
        systemctl daemon-reload && systemctl restart docker
        systemctl enable docker
        systemctl enable kubelet && systemctl start kubelet
        kubeadm init –kubernetes-version=1.21.0 –apiserver-advertise-address=192.168.57.101 –pod-network-cidr=10.244.0.0/16
        kubeadm token create –print-join-command (it’s also in the output of the previous command)
        kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
        </code>
    </pre>
</details>
<hr><br>

## 2. Upgrade an existing cluster
Using the new cluster from task #1, upgrade the cluster to v1.23.0 ensuring you do this in the least disruptive way. 

<br><hr>
<details>
  <summary>Click to show answer!</summary>
  <br><hr>
    The process to do this is roughly:<br>
    - Control plane: corden, upgrade kubeadm version plan/apply, upgrade kubelet/kubectl, uncordon<br>
    - Worker node: corden, upgrade kubeadm/kubelet, uncordon (repeat for node 2)<br>
    <b>Crucially</b>, make sure you drain the nodes where possible (corden/uncorden).<br><br>
    Make sure you read the output from the kubeadm plan. You will need to upgrade to v1.22.x before upgrading to v1.23.0!! (Use v1.22.1 - I think there was a problem with v1.22.0 IIRC).
    <pre>
        <code>
        # Control Plane Node:<br>
        k drain cluster2-master1 –ignore-daemonsets
        k cordon cluster2-master1 (should already be cordoned by the previous command)
        apt-get update && apt-get install -y –allow-change-held-packages kubeadm=1.23.0-00
        kubeadm upgrade plan v1.23.0
        kubeadm upgrade apply v1.23.0
        apt-get install -y kubelet=1.23.0-00 kubectl=1.23.0-00
        systemctl daemon-reload
        systemctl restart kubelet
        k uncorden master1
        <br>
        # Worker nodes:<br>
        k drain cluster2-worker1 –ignore-daemonsets
        k cordon cluster2-worker1
        apt-get install -y kubeadm=1.23.0-00
        kubeadm upgrade node
        apt-get install -y –allow-change-held-packages kubelet=1.23.0-00
        systemctl daemon-reload && systemctl restart kubelet
        k uncordon cluster2-worker1
        </code>
    </pre>
</details>
<hr><br>

## 3. ETCd - Backup and Restore
1. Create a namespace called `backup` and create a deployment called `test-backup` in the `backup` namespace, running an nginx:alpine image.
1. Take a backup of the ETCd cluster
1. Delete the deployment, `test-backup`
1. Restore the backup and confirm the `test-backup` pods have returned

<br><hr>
<details>
  <summary>Click to show answer!</summary>
  <br><hr>
    You'll need the certs to access the etcd cluster. As the pod is a static pod, you can find the location of these on the host, by looking at the ETCd manifest (/etc/kubernetes/manifests). Use this manifest to choose a suitable location to save the backup (eg a mounted volume on the host)<br><br>
    The command for backing up the database is:<br>
    <pre>
        <code>
        etcdctl –cacert=... –cert=... –key=... snapshot save /var/lib/etcd/my-backup.db
        </code>
    </pre>
    <br>
    And to restore:<br>
    <pre>
        <code>
        etcdctl –cacert=... –cert=... –key=... –data-dir=/var/lib/etcd/restored-db snapshot restore /var/lib/etc/my-backup.db
        </code>
    </pre>    
    <br>
    Then update the ETCd manifest to point the data-dir to the new data dir the above command has created. <br><br>
    <b>Note:</b> You can run etcdctl commands from the ETCd pod running on the control plane node. Just prefix the above commands with the appropriate <i>kubectl exec...</i> command.
</details>
<hr><br>
