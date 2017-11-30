#!/usr/bin/env bash

rm -rf kubernetes-vagrant-coreos-cluster

git clone https://github.com/pires/kubernetes-vagrant-coreos-cluster.git

cd kubernetes-vagrant-coreos-cluster
mv ~/.kube/config ~/.kube/config.pre-vagrant

NODE_MEM=2048 NODE_CPUS=1 NODES=2 MASTER_CPUS=1 USE_KUBE_UI=true DOCKER_OPTIONS="--insecure-registry=registry:5000" vagrant up

kubectl apply -f ../kubernetes/registry-deployment.yaml
kubectl apply -f ../kubernetes/jenkins-deployment.yaml


#kubectl port-forward $(kubectl get po | grep jenkins | awk '{print $1}') 8080:8080 && curl -XPOST http://localhost:8080/job/springboot_demo/build?token=jenkinsToken