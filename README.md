# Kubernetes CKA Example Environments
This is a somewhat modified version of the upstream forked repo by Kim Wuestkamp. The main changes are the Kubernetes version which gets installed and the second cluster which doesn't install K8s in the bootstrap scripts. The aim here is to have a similar environment in which I could install K8s control plane components by scratch.

I've added some tasks which I used when revising for the CKA. I've tried to cover questions which are outlined in the syllabus. They helped me with learning the _imperative_ commands which are needed when taking the exam so hopefully they can help others too.

## Clusters
There are 2 clusters in this repo. [Cluster 1](./cluster1/) will spin up a 3 node cluster (1 control plane and 2 workers) running a non-latest version of Kubernetes using `kubeadm`. [Cluster 2](./cluster2/) will spin up 3 Ubuntu nodes without K8s installed which will allow you to install the necessary components from scratch.

### Cluster 1
A 1 control plane / 2 worker node cluster. Can be used for upgrading the cluster, backing up/restoring ETCd and managing other K8s objects

cluster1-master1: 192.168.56.101
cluster1-worker1: 192.168.56.102
cluster1-worker2: 192.168.56.103

### Cluster 2
3 virtual machines **without** kubernetes setup. Can be used for going through the installation process using `kubeadm`.

cluster1-master1: 192.168.57.101
cluster1-worker1: 192.168.57.102
cluster1-worker2: 192.168.57.103

For convienience, the bootstrap scripts does the following already:

- Disable swap
- Add apt gpg key
- Add kubernetes repo list
- Apt-get update


## Prerequisites

1. Install [virtualbox](https://www.virtualbox.org/manual/ch02.html) and [vagrant](https://www.vagrantup.com/docs/installation)
1. This repo, cloned to your local machine

## Using this repo

### Starting the cluster
Browse to the cluster directory you want (cluster1 or cluster2) and run `./up.sh`. This can take a while (in the region of 5 mins). More if you're downloading the base VM image for the first time.

### Logging on
Run the following commands to log in to the control plane node:

```bash
vagrant ssh cluster1-master1
sudo -i
kubectl get node
```

**Note:** Log onto other nodes within the cluster from the master node: `ssh root@cluster1-worker1`

And you're ready to start the [tasks](#tasks)

### Tear Down

If you want to destroy the environment run `./down.sh` in the cluster directory you want to delete.


## Tasks
There are 2 sets of tasks - one for cluster1 and another for cluster2. Cluster1 is for K8s objects/management and cluster2 is used just for installing the K8s controlplane components from scratch, using `kubeadm`.

**Tip:** The tasks are best read from github.com directly as they use HTML elements to hide the answers!

- [Cluster 1 Tasks](./tasks-cluster1.md)
- [Cluster 2 Tasks](./tasks-cluster2.md)


For an exam-like experience, try sticking to using only the docs in [kubenetes.io](https://kubernetes.io/docs/home/) and `kubectl explain`. I found learning how to naviage `kubectl explain` super helpful, even if it takes a while to get used to it. However, you'll still need to use the docs from kubernetes.io for some things (pro-tip: the search is your friend!)
