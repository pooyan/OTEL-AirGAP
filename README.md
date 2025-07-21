# OpenTelemetry Air-Gap Deployment Tool

A comprehensive script to download and deploy a complete OpenTelemetry observability stack in air-gapped Kubernetes/OpenShift environments.

## 🎯 Overview

This script creates a self-contained package with intial required packages, tools, etc to build a observability platform:
- **Traces**: Jaeger + Tempo
- **Metrics**: Prometheus + Grafana  
- **Logs**: Loki + Elasticsearch (ELK Stack)
- **Collection**: OpenTelemetry Collector (contrib)
- **Visualization**: Grafana + Kibana

## 📦 What's Included

### Container Images (23+ images)
- **OpenTelemetry**: Operator + Collector (contrib version)
- **Jaeger**: All-in-one, Collector, Query
- **Tempo**: Tracing backend + Query interface
- **Prometheus**: Server + Alertmanager + Node/Blackbox Exporters
- **Grafana**: Dashboard platform
- **Loki**: Log aggregation + Promtail
- **Elasticsearch**: Search engine + Kibana + Logstash + Beats

### Binaries & Tools
- **Go** (latest version - dynamically fetched)
- **Helm** (latest version)
- **OpenTelemetry Collector** contrib binary

### Deployment Assets
- Kubernetes/OpenShift manifests
- Helm charts for all components
- Automated deployment scripts
- Complete documentation

## 🚀 Quick Start

### Step 1: Download Components (Internet-Connected Machine)

```bash
# Clone the repository
git clone git@github.com:pooyan/OTEL-AirGAP.git
cd OTEL-AirGAP

# Make script executable
chmod +x otel-offline-setup.sh

# Download everything with latest versions
./otel-offline-setup.sh
```

### Step 2: Transfer to Air-Gapped Environment

```bash
# Copy the generated package (typically 2-3GB)
scp otel-offline-package.tar.gz user@your-openshift-host:/tmp/
```

### Step 3: Deploy in OpenShift/Kubernetes

```bash
# Extract the package
tar -xzf otel-offline-package.tar.gz
cd otel-offline-package/scripts

# For OpenShift (recommended)
bash deploy-otel-openshift.sh

# For Kubernetes
bash deploy-otel-kubernetes.sh
```

## ⚙️ Advanced Usage

### Version Control

**Use Latest Versions (Default):**
```bash
./otel-offline-setup.sh
```

**Override Specific Versions:**
```bash
# Override individual components
GRAFANA_VERSION="10.0.0" ./otel-offline-setup.sh

# Override multiple components
GRAFANA_VERSION="10.0.0" \
PROMETHEUS_VERSION="2.45.0" \
ELASTICSEARCH_VERSION="8.10.0" \
./otel-offline-setup.sh

# Set versions in environment
export GRAFANA_VERSION="10.0.0"
export LOKI_VERSION="2.8.0"
./otel-offline-setup.sh
```

**Available Version Variables:**
- `OTEL_OPERATOR_VERSION`
- `OTEL_COLLECTOR_VERSION`
- `JAEGER_VERSION`
- `PROMETHEUS_VERSION`
- `GRAFANA_VERSION`
- `LOKI_VERSION`
- `TEMPO_VERSION`
- `ELASTICSEARCH_VERSION`
- `KIBANA_VERSION`
- `LOGSTASH_VERSION`
- `GO_VERSION`
- `HELM_VERSION`

### Manual Deployment Steps

If you prefer manual control:

```bash
# Load container images
cd scripts
bash load-images.sh

# Deploy individual components
oc apply -f ../manifests/otel-operator.yaml
oc apply -f ../manifests/jaeger-all-in-one.yaml

# Install with Helm
cd ../charts
helm install otel-collector opentelemetry-collector-*.tgz --namespace opentelemetry-system --create-namespace
helm install prometheus kube-prometheus-stack-*.tgz --namespace monitoring --create-namespace
```

## 🔍 Access Your Observability Platform

### OpenShift (with Routes)
After deployment, the script will show you the URLs:
- **Jaeger UI**: `https://jaeger-ui-jaeger-system.apps.your-cluster.com`
- **Grafana**: `https://grafana-monitoring.apps.your-cluster.com`
- **Prometheus**: `https://prometheus-monitoring.apps.your-cluster.com`

### Kubernetes (with Port-Forward)
```bash
# Jaeger UI
kubectl port-forward -n jaeger-system svc/jaeger-service 16686:16686

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Default Credentials:**
- **Grafana**: admin/prom-operator

## 📋 Prerequisites

### Internet-Connected Machine (for downloading)
- Docker
- Helm 3.x
- curl
- bash

### Air-Gapped Environment (for deployment)
- Kubernetes 1.24+ or OpenShift 4.x
- Docker runtime on all nodes
- Sufficient resources (4+ CPU cores, 8GB+ RAM recommended)
- `oc` CLI (for OpenShift) or `kubectl` (for Kubernetes)

## 📊 Package Structure

```
otel-offline-package/
├── images/                 # Container images (.tar files)
├── charts/                 # Helm charts (.tgz files)
├── manifests/             # Kubernetes YAML files
├── binaries/              # Go, Helm, OTEL binaries
├── scripts/               # Deployment automation
│   ├── deploy-otel-openshift.sh
│   ├── deploy-otel-kubernetes.sh
│   ├── load-images.sh
│   └── README.md
└── tools/                 # Additional utilities
```

## 🛠️ Troubleshooting

### Check Deployment Status
```bash
# Check all pods
oc get pods -A | grep -E "(otel|jaeger|prometheus|grafana|loki|elastic)"

# Check specific namespace
oc get pods -n opentelemetry-system
oc get pods -n jaeger-system
oc get pods -n monitoring
```

### View Logs
```bash
# Check pod logs
oc logs -n <namespace> <pod-name>

# Check operator logs
oc logs -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
```

### Verify Images
```bash
# Check loaded images
docker images | grep -E "(otel|jaeger|prometheus|grafana|loki|elastic)"
```

### Common Issues

**1. Image Pull Errors**
- Ensure all images are loaded: `bash scripts/load-images.sh`
- Check image names match: `docker images`

**2. Insufficient Resources**
- Monitor resource usage: `oc top nodes`
- Scale down non-essential workloads

**3. Network Policies**
- Ensure proper network policies for inter-pod communication
- Check service endpoints: `oc get svc -A`

## 📝 Logging & Monitoring

The download script provides comprehensive logging:
- **download.log**: Detailed download progress
- **errors.log**: Specific error information for failed components

Example log monitoring:
```bash
# Monitor download progress
tail -f download.log

# Check for errors
cat errors.log
```

## 🔧 Customization

### Modify Collector Configuration
Edit `manifests/otel-collector-config.yaml` before deployment to customize:
- **Receivers**: OTLP, Prometheus, etc.
- **Processors**: Batch, memory_limiter, etc.
- **Exporters**: Jaeger, Prometheus, etc.

### Add Custom Dashboards
Place Grafana dashboard JSON files in the package and import them post-deployment.

### Extend with Additional Components
Add more container images to the `IMAGES` array in `otel-offline-setup.sh`.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in your environment
5. Submit a pull request

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/pooyan/OTEL-AirGAP/issues)
- **Discussions**: [GitHub Discussions](https://github.com/pooyan/OTEL-AirGAP/discussions)

## 🏷️ Version History

- **v1.0.0**: Initial release with complete observability stack
- Dynamic version fetching
- OpenShift and Kubernetes support
- Comprehensive error handling and logging

---
