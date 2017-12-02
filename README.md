# k8s-automation

### Requirements

* make sure you have latest Vagrant, VirtualBox, git for your OS installed.
* This was tested on Mac OS 10.13.1, but should work on Linux boxes too
* Make sure you have at least 8GB RAM and 4 cores, as solution needs 5GB and 3 cores for it's VMs

### Startup:

```bash
git clone https://github.com/mkozinenko/k8s-automation.git

cd k8s-automation

./start.sh
```

You will be prompted for host sudo password to mount NFS volumes (modify /etc/exports in Mac OS case)

### Operating:

you can use kubectl to operate created K8s cluster. All app-related stuff is deployed in 'default' namespace

you can manually map Jenkins pod and check/trigger job 

Deployment scaling (up and down):

```bash
kubectl scale deployment springboot-demo --replicas=5
```
Replace 5 with desired number of replicas

### Extending:

You can easily add Fluentd+ES+Kibana to current solution using kubectl and provided yaml files on

https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

### Cleanup:

```bash
cd kubernetes-vagrant-coreos-cluster
NODES=2 vagrant destroy -f
```

you will be prompted for host sudo password to unmount NFS volumes (modify /etc/exports in Mac OS case)