#!/usr/bin/env bash

# deployment scale wrapper (needed due to DNS issue)
export DNS_IP=`kubectl get svc kube-dns --namespace=kube-system | awk 'NR>1{print $2}'`
kubectl scale deployment springboot-demo --replicas=$1
for ((i=1; i<=$NODE_COUNT;i++)) ;do vagrant ssh node-0$i -c "echo nameserver $DNS_IP |sudo tee -a /etc/resolv.conf";done
kubectl rollout status deployment/springboot-demo