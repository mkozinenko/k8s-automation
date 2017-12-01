#!/usr/bin/env bash

export NODE_COUNT=2

rm -rf kubernetes-vagrant-coreos-cluster

git clone https://github.com/pires/kubernetes-vagrant-coreos-cluster.git

cd kubernetes-vagrant-coreos-cluster
mv ~/.kube/config ~/.kube/config.pre-vagrant

NODE_MEM=2048 NODE_CPUS=1 NODES=$NODE_COUNT MASTER_CPUS=1 USE_KUBE_UI=true DNS_PROVIDER=coredns DOCKER_OPTIONS="--insecure-registry=registry.default.svc.cluster.local:5000" vagrant up



#kubectl apply -f ../kubernetes/calico-service.yml
kubectl apply -f ../kubernetes/registry-deployment.yaml
kubectl apply -f ../kubernetes/jenkins-deployment.yaml

kubectl rollout status deployment/jenkins-master

sleep 20
export DNS_IP=`kubectl get svc kube-dns --namespace=kube-system | awk 'NR>1{print $2}'`

vagrant ssh master -c "echo nameserver=$DNS_IP |sudo tee -a /etc/resolv.conf"
for ((i=1; i<=$NODE_COUNT;i++)) ;do vagrant ssh node-0$i -c "echo nameserver=$DNS_IP |sudo tee -a /etc/resolv.conf";done

kubectl port-forward $(kubectl get po | grep jenkins-master | awk '{print $1}') 8080:8080 2>&1 >/dev/null&


echo "Triggering buildjob when Jenkins will be ready..."
sleep 120

job_started="When job will be started successfuly, this env will be empty"
until [ -z "$job_started" ]; do job_started=`curl -s -XPOST http://admin:admin@localhost:8080/job/springboot_demo/build?token=jenkinsToken | grep "<title>"` && sleep 60;done

echo "Checking if build job completed... please wait. You can check progress at http://localhost:8080/job/springboot_demo/"

vagrant ssh master -c "echo nameserver=$DNS_IP |sudo tee -a /etc/resolv.conf"
for ((i=1; i<=$NODE_COUNT;i++)) ;do vagrant ssh node-0$i -c "echo nameserver=$DNS_IP |sudo tee -a /etc/resolv.conf";done

job_status=''
until [ -n "$job_status" ]; do job_status=`curl -s http://admin:admin@localhost:8080/job/springboot_demo/lastBuild/api/json | grep "\"buildResult\":\"SUCCESS\""` && sleep 60;done

export PFW_PID=`ps -ef | grep "kubectl port-forward"| awk 'FNR==1{print $2}'`
echo "Killing Jenkins port-forward process, PID:":$PFW_PID"..."
kill -9 $PFW_PID
export SERVICE_PORT=`kubectl get svc springboot-demo -o yaml | grep nodePort | awk '{print $2}'`
export MASTER_IP=`vagrant ssh master -c "ifconfig eth1 | grep inet" | awk 'FNR == 1 {print $2}'`

curl $MASTER_IP:$SERVICE_PORT

echo "Please, check springboot-demo application at http://"$MASTER_IP":"$SERVICE_PORT
echo "Kubernetes Dashboard is accessible at http://"$MASTER_IP":8080/ui"