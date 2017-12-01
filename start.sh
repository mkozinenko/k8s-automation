#!/usr/bin/env bash

# set number of nodes below
export NODE_COUNT=2

# prepare...
rm -rf kubernetes-vagrant-coreos-cluster

git clone https://github.com/pires/kubernetes-vagrant-coreos-cluster.git

cd kubernetes-vagrant-coreos-cluster
mv ~/.kube/config ~/.kube/config.pre-vagrant

# create k8s cluster
NODE_MEM=2048 NODE_CPUS=1 NODES=$NODE_COUNT MASTER_CPUS=1 USE_KUBE_UI=true DOCKER_OPTIONS="--insecure-registry=registry.default.svc.cluster.local:5000" vagrant up


# apply jenkins and registry manifests. You can edd ELK and/or monitoring here
# uncomment below to enable standalone monitoring with heapster
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.7.0.yaml
kubectl apply -f ../kubernetes/registry-deployment.yaml
kubectl apply -f ../kubernetes/jenkins-deployment.yaml

# check if Jenkins rolled out.
kubectl rollout status deployment/jenkins-master
sleep 20

# get kube_dns cluster IP
export DNS_IP=`kubectl get svc kube-dns --namespace=kube-system | awk 'NR>1{print $2}'`

# connect to Jenkins using localhost port mapping
kubectl port-forward $(kubectl get po | grep jenkins-master | awk '{print $1}') 8080:8080 2>&1 >/dev/null&


echo "Triggering buildjob when Jenkins will be ready..."
sleep 60

job_started="When job will be started successfuly, this env will be empty"
until [ -z "$job_started" ]; do job_started=`curl -s -XPOST http://admin:admin@localhost:8080/job/springboot_demo/build?token=jenkinsToken | grep "<title>"` && sleep 60;done

echo "Checking if build job completed... please wait. You can check progress at http://localhost:8080/job/springboot_demo/"

job_status=''
until [ -n "$job_status" ]; do job_status=`curl -s http://admin:admin@localhost:8080/job/springboot_demo/lastBuild/api/json | grep "\"building\":false"` && sleep 60;done

# dirty hack to workaround vagrant+coreos resolve issue, that prevents working with internal services like registry on host level.
vagrant ssh master -c "echo nameserver $DNS_IP |sudo tee -a /etc/resolv.conf"
for ((i=1; i<=$NODE_COUNT;i++)) ;do vagrant ssh node-0$i -c "echo nameserver $DNS_IP |sudo tee -a /etc/resolv.conf";done

# check if springboot was rolled out correctly
kubectl rollout status deployment/springboot-demo

# get portforward process PID
export PFW_PID=`ps -ef | grep "kubectl port-forward"| awk 'FNR==1{print $2}'`
echo "Killing Jenkins port-forward process, PID:":$PFW_PID"..."
kill -9 $PFW_PID

# get springboot url
export SERVICE_PORT=`kubectl get svc springboot-demo -o yaml | grep nodePort | awk '{print $2}'`
export MASTER_IP=`vagrant ssh master -c "ifconfig eth1 | grep inet" | awk 'FNR == 1 {print $2}'`

curl $MASTER_IP:$SERVICE_PORT

echo "Please, check springboot-demo application at http://"$MASTER_IP":"$SERVICE_PORT
echo "Kubernetes Dashboard is accessible at http://"$MASTER_IP":8080/ui"