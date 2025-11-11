#!/bin/bash

set -e

echo "🔥 Deleting old Kind cluster..."
kind delete cluster || true

echo "🚀 Creating new Kind cluster with Ingress ports exposed..."
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "⏳ Waiting for cluster to be ready..."
sleep 10

echo "🛡️ Installing NGINX Ingress Controller..."
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=ingress-nginx \
  --timeout=90s


echo "📦 Applying Kubernetes manifests..."
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment complete!"
echo ""
kubectl get pods
echo ""
kubectl get svc
echo ""
kubectl get ingress
echo ""
echo "🌐 Visit your app at: http://localhost/"
