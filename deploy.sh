#!/bin/bash

echo "🚀 Deploying Task Manager to Kubernetes..."

# Create kind cluster
kind create cluster --name task-manager --config kind-config.yaml

# Deploy database
kubectl apply -f k8s/database.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Deploy app
kubectl apply -f k8s/app.yaml
kubectl wait --for=condition=ready pod -l app=taskmanager-app --timeout=120s

# Show status
kubectl get all

echo "✅ Deployment complete! Access your app at: http://localhost:5001"