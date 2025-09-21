#!/bin/bash

echo "Installing monitoring stack in three-tier namespace..."

# Install Prometheus
echo "Installing Prometheus..."
kubectl apply -f prometheus/prometheus-service.yaml
kubectl apply -f prometheus/prometheus-config.yaml
kubectl apply -f prometheus/prometheus-deployment.yaml

# Install Grafana
echo "Installing Grafana..."
kubectl apply -f grafana/grafana-deployment.yaml
kubectl apply -f grafana/grafana-service.yaml

# Update backend deployment with Prometheus annotations
echo "Updating backend deployment with monitoring annotations..."
#kubectl apply -f ../../backend/deployment.yaml

echo "Monitoring stack deployed successfully in three-tier namespace!"
echo ""
echo "To access Grafana:"
echo "  kubectl get svc -n three-tier grafana-service"
echo "  kubectl port-forward -n three-tier svc/grafana-service 3000:3000"
echo ""
echo "To access Prometheus:"
echo "  kubectl port-forward -n three-tier svc/prometheus-service 9090:9090"
echo "To Access grafana use lburl:3000"
echo "Grafana credentials: admin / admin123"
