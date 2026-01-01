#!/bin/bash

echo "=== EKS Cluster Health Check ==="

# Check kubectl connectivity
echo "1. Testing kubectl connectivity..."
kubectl cluster-info

# Check nodes
echo -e "\n2. Checking nodes..."
kubectl get nodes -o wide

# Check system pods
echo -e "\n3. Checking system pods..."
kubectl get pods -n kube-system

# Check critical addons
echo -e "\n4. Checking critical addons..."
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Check storage classes
echo -e "\n5. Checking storage classes..."
kubectl get storageclass

# Check network policies
echo -e "\n6. Checking network policies..."
kubectl get networkpolicies -A

echo -e "\n=== Health Check Complete ==="