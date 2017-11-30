#!/usr/bin/env bash

rm -rf kubernetes-vagrant-coreos-cluster

git clone https://github.com/pires/kubernetes-vagrant-coreos-cluster.git

cd kubernetes-vagrant-coreos-cluster
mv ~/.kube/config ~/.kube/config.pre-vagrant

NODE_MEM=2048 NODE_CPUS=1 NODES=2 MASTER_CPUS=1 USE_KUBE_UI=true DOCKER_OPTIONS="--insecure-registry=registry.default.svc.cluster.local:5000" vagrant up

kubectl apply -f ../kubernetes/registry-deployment.yaml
kubectl apply -f ../kubernetes/jenkins-deployment.yaml


kubectl rollout status deployment/jenkins-master
kubectl port-forward $(kubectl get po | grep jenkins-master | awk '{print $1}') 8080:8080 && curl -XPOST http://admin:admin@localhost:8080/job/springboot_demo/build?token=jenkinsToken

#job_status=`curl http://admin:admin@localhost:8080/job/springboot_demo/lastBuild/api/json | grep "\"result\":\"SUCCESS\""`

#if [ -n "$job_status" ]
#then
    # Run your script commands here
#else
#  echo "BUILD FAILURE: Other build is unsuccessful or status could not be obtained."
#  exit 1
#fi