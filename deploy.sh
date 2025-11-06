#!/bin/bash

echo "🔥 Deleting old Kind cluster..."
kind delete cluster

echo "🚀 Creating new Kind cluster..."
kind create cluster

echo "⏳ Waiting for cluster to be ready..."
sleep 10  # optional pause to let control plane settle

echo "📦 Applying Kubernetes manifests..."
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml


kubectl apply -f k8s/ingress.yaml  # if you have a separate file


echo "📥 Applying Ingress rules..."
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment complete!"
kubectl get pods
kubectl get svc
kubectl get ingress
