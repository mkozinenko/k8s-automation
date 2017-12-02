#!/usr/bin/env bash
export NODE_COUNT=2

for ((i=2;i<=$NODE_COUNT+1;i++)); do kubectl label no 172.17.8.10$i beta.kubernetes.io/fluentd-ds-ready=true; done
kubectl apply -f logging/