#!/bin/bash

echo "🚀 Deploying Task Manager from Docker Hub..."

# Create Kind cluster
kind create cluster --config k8s/kind-config.yaml


echo "✅ Cluster created"

# Install Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Deploy application
kubectl apply -f  k8s/postgres.yaml
kubectl apply -f  k8s/backend.yaml
kubectl apply -f  k8s/ingress.yaml

echo "⏳ Waiting for pods to be ready..."
sleep 30

# Check status
echo "📊 Deployment Status:"
kubectl get pods
kubectl get services
kubectl get ingress

echo ""
echo "🎉 Task Manager deployed!"
echo "📍 Access your app at: http://localhost"
echo "🔍 API available at: http://localhost/api"