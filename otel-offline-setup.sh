#!/bin/bash

# OpenTelemetry Offline Deployment Script
# This script downloads all necessary components for a complete OTEL deployment
# Run this on a machine with internet access, then transfer the output to your air-gapped environment

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="${SCRIPT_DIR}/otel-offline-package"
IMAGES_DIR="${DOWNLOAD_DIR}/images"
CHARTS_DIR="${DOWNLOAD_DIR}/charts"
MANIFESTS_DIR="${DOWNLOAD_DIR}/manifests"
SCRIPTS_DIR="${DOWNLOAD_DIR}/scripts"
BINARIES_DIR="${DOWNLOAD_DIR}/binaries"
TOOLS_DIR="${DOWNLOAD_DIR}/tools"

# Version Configuration - Set to empty string to fetch latest, or specify version
# You can override any version by setting environment variables before running the script
# Example: GRAFANA_VERSION="9.5.0" ./otel-offline-setup.sh

# OpenTelemetry versions (leave empty for latest)
OTEL_OPERATOR_VERSION="${OTEL_OPERATOR_VERSION:-}"
OTEL_COLLECTOR_VERSION="${OTEL_COLLECTOR_VERSION:-}"
JAEGER_VERSION="${JAEGER_VERSION:-}"

# Metrics & Visualization versions (leave empty for latest)
PROMETHEUS_VERSION="${PROMETHEUS_VERSION:-}"
GRAFANA_VERSION="${GRAFANA_VERSION:-}"

# Logging stack versions (leave empty for latest)
LOKI_VERSION="${LOKI_VERSION:-}"
TEMPO_VERSION="${TEMPO_VERSION:-}"
ELASTICSEARCH_VERSION="${ELASTICSEARCH_VERSION:-}"
KIBANA_VERSION="${KIBANA_VERSION:-}"
LOGSTASH_VERSION="${LOGSTASH_VERSION:-}"

# Tool versions (leave empty for latest)
GO_VERSION="${GO_VERSION:-}"
HELM_VERSION="${HELM_VERSION:-}"
OTELCOL_CONTRIB_VERSION="${OTELCOL_CONTRIB_VERSION:-}"

# Dynamic version fetching functions
get_latest_versions() {
    log_info "Fetching latest versions for all components..."
    
    # Get latest Go version
    if [[ -z "$GO_VERSION" ]]; then
        log_info "Fetching latest Go version..."
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1 | sed 's/go//' 2>/dev/null)
        if [[ -z "$GO_VERSION" ]]; then
            log_error "Failed to fetch latest Go version, using fallback"
            GO_VERSION="1.22.0"
        fi
        log_success "Using Go version: ${GO_VERSION}"
    fi
    
    # Get latest Helm version
    if [[ -z "$HELM_VERSION" ]]; then
        log_info "Fetching latest Helm version..."
        HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$HELM_VERSION" ]]; then
            log_error "Failed to fetch latest Helm version, using fallback"
            HELM_VERSION="3.13.3"
        fi
        log_success "Using Helm version: ${HELM_VERSION}"
    fi
    
    # Get latest OpenTelemetry versions
    if [[ -z "$OTEL_OPERATOR_VERSION" ]]; then
        log_info "Fetching latest OpenTelemetry Operator version..."
        OTEL_OPERATOR_VERSION=$(curl -s https://api.github.com/repos/open-telemetry/opentelemetry-operator/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$OTEL_OPERATOR_VERSION" ]]; then
            log_error "Failed to fetch latest OTEL Operator version, using fallback"
            OTEL_OPERATOR_VERSION="0.88.0"
        fi
        log_success "Using OTEL Operator version: ${OTEL_OPERATOR_VERSION}"
    fi
    
    if [[ -z "$OTEL_COLLECTOR_VERSION" ]]; then
        log_info "Fetching latest OpenTelemetry Collector version..."
        OTEL_COLLECTOR_VERSION=$(curl -s https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$OTEL_COLLECTOR_VERSION" ]]; then
            log_error "Failed to fetch latest OTEL Collector version, using fallback"
            OTEL_COLLECTOR_VERSION="0.88.0"
        fi
        log_success "Using OTEL Collector version: ${OTEL_COLLECTOR_VERSION}"
        OTELCOL_CONTRIB_VERSION="$OTEL_COLLECTOR_VERSION"
    fi
    
    # Get latest Jaeger version
    if [[ -z "$JAEGER_VERSION" ]]; then
        log_info "Fetching latest Jaeger version..."
        JAEGER_VERSION=$(curl -s https://api.github.com/repos/jaegertracing/jaeger/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$JAEGER_VERSION" ]]; then
            log_error "Failed to fetch latest Jaeger version, using fallback"
            JAEGER_VERSION="1.51.0"
        fi
        log_success "Using Jaeger version: ${JAEGER_VERSION}"
    fi
    
    # Get latest Prometheus version
    if [[ -z "$PROMETHEUS_VERSION" ]]; then
        log_info "Fetching latest Prometheus version..."
        PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$PROMETHEUS_VERSION" ]]; then
            log_error "Failed to fetch latest Prometheus version, using fallback"
            PROMETHEUS_VERSION="2.47.2"
        fi
        log_success "Using Prometheus version: ${PROMETHEUS_VERSION}"
    fi
    
    # Get latest Grafana version
    if [[ -z "$GRAFANA_VERSION" ]]; then
        log_info "Fetching latest Grafana version..."
        GRAFANA_VERSION=$(curl -s https://api.github.com/repos/grafana/grafana/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$GRAFANA_VERSION" ]]; then
            log_error "Failed to fetch latest Grafana version, using fallback"
            GRAFANA_VERSION="10.2.0"
        fi
        log_success "Using Grafana version: ${GRAFANA_VERSION}"
    fi
    
    # Get latest Loki version
    if [[ -z "$LOKI_VERSION" ]]; then
        log_info "Fetching latest Loki version..."
        LOKI_VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$LOKI_VERSION" ]]; then
            log_error "Failed to fetch latest Loki version, using fallback"
            LOKI_VERSION="2.9.3"
        fi
        log_success "Using Loki version: ${LOKI_VERSION}"
    fi
    
    # Get latest Tempo version
    if [[ -z "$TEMPO_VERSION" ]]; then
        log_info "Fetching latest Tempo version..."
        TEMPO_VERSION=$(curl -s https://api.github.com/repos/grafana/tempo/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//' 2>/dev/null)
        if [[ -z "$TEMPO_VERSION" ]]; then
            log_error "Failed to fetch latest Tempo version, using fallback"
            TEMPO_VERSION="2.3.1"
        fi
        log_success "Using Tempo version: ${TEMPO_VERSION}"
    fi
    
    # Get latest Elasticsearch version (using Docker Hub API)
    if [[ -z "$ELASTICSEARCH_VERSION" ]]; then
        log_info "Fetching latest Elasticsearch version..."
        ELASTICSEARCH_VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/library/elasticsearch/tags/?page_size=100" | grep -o '"name":"[0-9]\+\.[0-9]\+\.[0-9]\+"' | head -1 | sed 's/"name":"//;s/"//' 2>/dev/null)
        if [[ -z "$ELASTICSEARCH_VERSION" ]]; then
            log_error "Failed to fetch latest Elasticsearch version, using fallback"
            ELASTICSEARCH_VERSION="8.11.3"
        fi
        log_success "Using Elasticsearch version: ${ELASTICSEARCH_VERSION}"
        KIBANA_VERSION="$ELASTICSEARCH_VERSION"
        LOGSTASH_VERSION="$ELASTICSEARCH_VERSION"
    fi
    
    log_success "All versions resolved successfully!"
}

# Logging setup
LOG_FILE="${SCRIPT_DIR}/download.log"
ERROR_LOG="${SCRIPT_DIR}/errors.log"

# Initialize log files
init_logging() {
    echo "=== OpenTelemetry Offline Package Download Log ===" > "${LOG_FILE}"
    echo "Started at: $(date)" >> "${LOG_FILE}"
    echo "=== Error Log ===" > "${ERROR_LOG}"
}

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${ERROR_LOG}" >&2
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# Container images array - will be built dynamically after version resolution
declare -a IMAGES=()

# Build images array with resolved versions
build_images_array() {
    log_info "Building container images list with resolved versions..."
    
    # Container images to download - Complete Observability Stack
    # spell-checker: disable-next-line
    IMAGES=(
        # OpenTelemetry Core
        "ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator:v${OTEL_OPERATOR_VERSION}"
        "otel/opentelemetry-collector-contrib:${OTEL_COLLECTOR_VERSION}"
        "otel/opentelemetry-collector:${OTEL_COLLECTOR_VERSION}"
        
        # Jaeger (Tracing)
        "jaegertracing/jaeger-operator:${JAEGER_VERSION}"
        "jaegertracing/all-in-one:${JAEGER_VERSION}"
        "jaegertracing/jaeger-collector:${JAEGER_VERSION}"
        "jaegertracing/jaeger-query:${JAEGER_VERSION}"
        "jaegertracing/jaeger-agent:${JAEGER_VERSION}"
        
        # Tempo (Alternative Tracing)
        "grafana/tempo:${TEMPO_VERSION}"
        "grafana/tempo-query:${TEMPO_VERSION}"
        
        # Prometheus Stack (Metrics)
        "prom/prometheus:v${PROMETHEUS_VERSION}"
        "grafana/grafana:${GRAFANA_VERSION}"
        "prom/node-exporter:v1.6.1"
        "prom/blackbox-exporter:v0.24.0"
        "quay.io/prometheus/alertmanager:v0.26.0"
        "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"
        
        # Loki Stack (Logs)
        "grafana/loki:${LOKI_VERSION}"
        "grafana/promtail:${LOKI_VERSION}"
        
        # Elasticsearch Stack (Logs & Search)
        "docker.elastic.co/elasticsearch/elasticsearch:${ELASTICSEARCH_VERSION}"
        "docker.elastic.co/kibana/kibana:${KIBANA_VERSION}"
        "docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION}"
        "docker.elastic.co/beats/filebeat:${ELASTICSEARCH_VERSION}"
        "docker.elastic.co/beats/metricbeat:${ELASTICSEARCH_VERSION}"
    )
    
    log_success "Built images list with ${#IMAGES[@]} container images"
}

echo "=== OpenTelemetry Offline Package Creator ==="
echo "This script will download all components needed for OTEL deployment"
echo "Package will be created in: ${DOWNLOAD_DIR}"
echo

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    log_success "Docker found"
    
    if ! command -v helm &> /dev/null; then
        log_error "Helm is required but not installed"
        exit 1
    fi
    log_success "Helm found"
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    log_success "curl found"
    
    log_success "All prerequisites found"
}

# Create directory structure
setup_directories() {
    log_info "Setting up directory structure..."
    rm -rf "${DOWNLOAD_DIR}"
    mkdir -p "${IMAGES_DIR}" "${CHARTS_DIR}" "${MANIFESTS_DIR}" "${SCRIPTS_DIR}" "${BINARIES_DIR}" "${TOOLS_DIR}"
    log_success "Directories created"
}

# Download and save container images
download_images() {
    log_info "Starting container image downloads..."
    local failed_images=()
    
    for image in "${IMAGES[@]}"; do
        log_info "Pulling ${image}..."
        if docker pull "${image}" >> "${LOG_FILE}" 2>&1; then
            # Save image to tar file
            image_name=$(echo "${image}" | sed 's/[\/:]/_/g')
            if docker save "${image}" -o "${IMAGES_DIR}/${image_name}.tar" >> "${LOG_FILE}" 2>&1; then
                log_success "Saved ${image}"
            else
                log_error "Failed to save ${image}"
                failed_images+=("${image}")
            fi
        else
            log_error "Failed to pull ${image}"
            failed_images+=("${image}")
        fi
    done
    
    # Create image list for loading script
    printf '%s\n' "${IMAGES[@]}" > "${IMAGES_DIR}/image-list.txt"
    
    if [[ ${#failed_images[@]} -eq 0 ]]; then
        log_success "All images downloaded and saved successfully"
    else
        log_error "Failed to download ${#failed_images[@]} images: ${failed_images[*]}"
        echo "Failed images:" >> "${ERROR_LOG}"
        printf '%s\n' "${failed_images[@]}" >> "${ERROR_LOG}"
    fi
}

# Download Helm charts
download_charts() {
    log_info "Starting Helm chart downloads..."
    local failed_charts=()
    
    # Add Helm repositories with error handling
    log_info "Adding Helm repositories..."
    if helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >> "${LOG_FILE}" 2>&1; then
        log_success "Added OpenTelemetry Helm repo"
    else
        log_error "Failed to add OpenTelemetry Helm repo"
        failed_charts+=("opentelemetry-repo")
    fi
    
    if helm repo add jaegertracing https://jaegertracing.github.io/helm-charts >> "${LOG_FILE}" 2>&1; then
        log_success "Added Jaeger Helm repo"
    else
        log_error "Failed to add Jaeger Helm repo"
        failed_charts+=("jaeger-repo")
    fi
    
    if helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >> "${LOG_FILE}" 2>&1; then
        log_success "Added Prometheus Helm repo"
    else
        log_error "Failed to add Prometheus Helm repo"
        failed_charts+=("prometheus-repo")
    fi
    
    if helm repo add grafana https://grafana.github.io/helm-charts >> "${LOG_FILE}" 2>&1; then
        log_success "Added Grafana Helm repo"
    else
        log_error "Failed to add Grafana Helm repo"
        failed_charts+=("grafana-repo")
    fi
    
    if helm repo add elastic https://helm.elastic.co >> "${LOG_FILE}" 2>&1; then
        log_success "Added Elastic Helm repo"
    else
        log_error "Failed to add Elastic Helm repo"
        failed_charts+=("elastic-repo")
    fi
    
    if helm repo update >> "${LOG_FILE}" 2>&1; then
        log_success "Updated Helm repositories"
    else
        log_error "Failed to update Helm repositories"
    fi
    
    # Download charts with error handling
    cd "${CHARTS_DIR}"
    
    log_info "Downloading OpenTelemetry Operator chart..."
    if helm pull open-telemetry/opentelemetry-operator --version "${OTEL_OPERATOR_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded OpenTelemetry Operator chart"
    else
        log_error "Failed to download OpenTelemetry Operator chart"
        failed_charts+=("opentelemetry-operator")
    fi
    
    log_info "Downloading OpenTelemetry Collector chart..."
    if helm pull open-telemetry/opentelemetry-collector --version "${OTEL_COLLECTOR_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded OpenTelemetry Collector chart"
    else
        log_error "Failed to download OpenTelemetry Collector chart"
        failed_charts+=("opentelemetry-collector")
    fi
    
    log_info "Downloading Jaeger Operator chart..."
    if helm pull jaegertracing/jaeger-operator --version "${JAEGER_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Jaeger Operator chart"
    else
        log_error "Failed to download Jaeger Operator chart"
        failed_charts+=("jaeger-operator")
    fi
    
    log_info "Downloading Jaeger chart..."
    if helm pull jaegertracing/jaeger --version "${JAEGER_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Jaeger chart"
    else
        log_error "Failed to download Jaeger chart"
        failed_charts+=("jaeger")
    fi
    
    log_info "Downloading Prometheus stack chart..."
    if helm pull prometheus-community/kube-prometheus-stack --version "54.0.1" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Prometheus stack chart"
    else
        log_error "Failed to download Prometheus stack chart"
        failed_charts+=("kube-prometheus-stack")
    fi
    
    log_info "Downloading Grafana chart..."
    if helm pull grafana/grafana --version "${GRAFANA_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Grafana chart"
    else
        log_error "Failed to download Grafana chart"
        failed_charts+=("grafana")
    fi
    
    # Download Loki stack charts
    log_info "Downloading Loki chart..."
    if helm pull grafana/loki --version "${LOKI_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Loki chart"
    else
        log_error "Failed to download Loki chart"
        failed_charts+=("loki")
    fi
    
    log_info "Downloading Promtail chart..."
    if helm pull grafana/promtail --version "${LOKI_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Promtail chart"
    else
        log_error "Failed to download Promtail chart"
        failed_charts+=("promtail")
    fi
    
    # Download Tempo chart
    log_info "Downloading Tempo chart..."
    if helm pull grafana/tempo --version "${TEMPO_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Tempo chart"
    else
        log_error "Failed to download Tempo chart"
        failed_charts+=("tempo")
    fi
    
    # Download Elasticsearch stack charts
    log_info "Downloading Elasticsearch chart..."
    if helm pull elastic/elasticsearch --version "${ELASTICSEARCH_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Elasticsearch chart"
    else
        log_error "Failed to download Elasticsearch chart"
        failed_charts+=("elasticsearch")
    fi
    
    log_info "Downloading Kibana chart..."
    if helm pull elastic/kibana --version "${KIBANA_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Kibana chart"
    else
        log_error "Failed to download Kibana chart"
        failed_charts+=("kibana")
    fi
    
    log_info "Downloading Logstash chart..."
    if helm pull elastic/logstash --version "${LOGSTASH_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Logstash chart"
    else
        log_error "Failed to download Logstash chart"
        failed_charts+=("logstash")
    fi
    
    log_info "Downloading Filebeat chart..."
    if helm pull elastic/filebeat --version "${ELASTICSEARCH_VERSION}" >> "${LOG_FILE}" 2>&1; then
        log_success "Downloaded Filebeat chart"
    else
        log_error "Failed to download Filebeat chart"
        failed_charts+=("filebeat")
    fi
    
    cd "${SCRIPT_DIR}"
    
    if [[ ${#failed_charts[@]} -eq 0 ]]; then
        log_success "All Helm charts downloaded successfully"
    else
        log_error "Failed to download ${#failed_charts[@]} charts: ${failed_charts[*]}"
        echo "Failed charts:" >> "${ERROR_LOG}"
        printf '%s\n' "${failed_charts[@]}" >> "${ERROR_LOG}"
    fi
}

# Download Go and other binaries (OpenShift-ready - no kubectl needed)
download_binaries() {
    log_info "Starting binary downloads..."
    local failed_binaries=()
    
    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="armv6l" ;;
    esac
    
    log_info "Detected OS: ${OS}, Architecture: ${ARCH}"
    cd "${BINARIES_DIR}"
    
    # Download Go (latest version)
    log_info "Downloading Go ${GO_VERSION}..."
    GO_ARCHIVE="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    if curl -LO "https://golang.org/dl/${GO_ARCHIVE}" >> "${LOG_FILE}" 2>&1; then
        if [[ -f "${GO_ARCHIVE}" ]]; then
            log_success "Downloaded Go ${GO_VERSION}"
        else
            log_error "Go archive not found after download"
            failed_binaries+=("go")
        fi
    else
        log_error "Failed to download Go ${GO_VERSION}"
        failed_binaries+=("go")
    fi
    
    # Download Helm
    log_info "Downloading Helm ${HELM_VERSION}..."
    HELM_ARCHIVE="helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
    if curl -LO "https://get.helm.sh/${HELM_ARCHIVE}" >> "${LOG_FILE}" 2>&1; then
        if [[ -f "${HELM_ARCHIVE}" ]]; then
            log_success "Downloaded Helm ${HELM_VERSION}"
        else
            log_error "Helm archive not found after download"
            failed_binaries+=("helm")
        fi
    else
        log_error "Failed to download Helm ${HELM_VERSION}"
        failed_binaries+=("helm")
    fi
    
    # Download OpenTelemetry Collector Contrib binary
    log_info "Downloading OTEL Collector Contrib binary ${OTELCOL_CONTRIB_VERSION}..."
    OTELCOL_ARCHIVE="otelcol-contrib_${OTELCOL_CONTRIB_VERSION}_${OS}_${ARCH}.tar.gz"
    if curl -LO "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_CONTRIB_VERSION}/${OTELCOL_ARCHIVE}" >> "${LOG_FILE}" 2>&1; then
        if [[ -f "${OTELCOL_ARCHIVE}" ]]; then
            log_success "Downloaded OTEL Collector Contrib binary"
        else
            log_error "OTEL Collector archive not found after download"
            failed_binaries+=("otelcol-contrib")
        fi
    else
        log_error "Failed to download OTEL Collector Contrib binary"
        failed_binaries+=("otelcol-contrib")
    fi
    
    cd "${SCRIPT_DIR}"
    
    if [[ ${#failed_binaries[@]} -eq 0 ]]; then
        log_success "All binaries downloaded successfully"
    else
        log_error "Failed to download ${#failed_binaries[@]} binaries: ${failed_binaries[*]}"
        echo "Failed binaries:" >> "${ERROR_LOG}"
        printf '%s\n' "${failed_binaries[@]}" >> "${ERROR_LOG}"
    fi
}

# Create Kubernetes manifests
create_manifests() {
    log_info "Creating Kubernetes manifests..."
    
    # OpenTelemetry Operator manifest
    cat > "${MANIFESTS_DIR}/otel-operator.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: opentelemetry-operator-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opentelemetry-operator-controller-manager
  namespace: opentelemetry-operator-system
spec:
  replicas: 1
  selector:
    matchLabels:
      control-plane: controller-manager
  template:
    metadata:
      labels:
        control-plane: controller-manager
    spec:
      containers:
      - name: manager
        image: ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator:v0.88.0
        ports:
        - containerPort: 8080
          name: metrics
        - containerPort: 8081
          name: health
        resources:
          limits:
            cpu: 200m
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 64Mi
EOF

    # OpenTelemetry Collector configuration
    cat > "${MANIFESTS_DIR}/otel-collector-config.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: opentelemetry-system
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus:
        config:
          scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
            - role: pod
    
    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      memory_limiter:
        limit_mib: 512
    
    exporters:
      jaeger:
        endpoint: jaeger-collector:14250
        tls:
          insecure: true
      prometheus:
        endpoint: "0.0.0.0:8889"
      logging:
        loglevel: debug
    
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [jaeger, logging]
        metrics:
          receivers: [otlp, prometheus]
          processors: [memory_limiter, batch]
          exporters: [prometheus, logging]
        logs:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [logging]
EOF

    # Jaeger all-in-one deployment
    cat > "${MANIFESTS_DIR}/jaeger-all-in-one.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: jaeger-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: jaeger-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.51.0
        ports:
        - containerPort: 16686
          name: ui
        - containerPort: 14250
          name: grpc
        - containerPort: 14268
          name: http
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-service
  namespace: jaeger-system
spec:
  selector:
    app: jaeger
  ports:
  - name: ui
    port: 16686
    targetPort: 16686
  - name: grpc
    port: 14250
    targetPort: 14250
  - name: http
    port: 14268
    targetPort: 14268
  type: ClusterIP
EOF

    echo "✓ Kubernetes manifests created"
}

# Create deployment scripts for air-gapped environment
create_deployment_scripts() {
    echo "Creating deployment scripts..."
    
    # Image loading script
    cat > "${SCRIPTS_DIR}/load-images.sh" << 'EOF'
#!/bin/bash
# Load all Docker images in air-gapped environment

set -e

IMAGES_DIR="$(dirname "$0")/../images"

echo "Loading Docker images..."

while IFS= read -r image; do
    image_name=$(echo "${image}" | sed 's/[\/:]/_/g')
    echo "Loading ${image}..."
    docker load -i "${IMAGES_DIR}/${image_name}.tar"
    echo "✓ Loaded ${image}"
done < "${IMAGES_DIR}/image-list.txt"

echo "All images loaded successfully!"
EOF

    # OpenShift-specific deployment script
    cat > "${SCRIPTS_DIR}/deploy-otel-openshift.sh" << 'EOF'
#!/bin/bash
# Deploy OpenTelemetry stack in air-gapped OpenShift environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenTelemetry OpenShift Air-Gapped Deployment ==="

# Load images
echo "Step 1: Loading Docker images..."
bash "${SCRIPT_DIR}/load-images.sh"

# Install Helm if needed
echo "Step 2: Installing Helm if needed..."
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    cd /tmp
    tar -xzf "${PACKAGE_DIR}/binaries/helm-v3.13.3-linux-amd64.tar.gz"
    sudo mv linux-amd64/helm /usr/local/bin/
    sudo chmod +x /usr/local/bin/helm
    echo "✓ Helm installed"
else
    echo "✓ Helm already available"
fi

# Deploy OpenTelemetry Operator
echo "Step 3: Deploying OpenTelemetry Operator..."
oc apply -f "${PACKAGE_DIR}/manifests/otel-operator.yaml"

# Wait for operator to be ready
echo "Waiting for operator to be ready..."
oc wait --for=condition=available --timeout=300s deployment/opentelemetry-operator-controller-manager -n opentelemetry-operator-system

# Deploy Jaeger
echo "Step 4: Deploying Jaeger..."
oc apply -f "${PACKAGE_DIR}/manifests/jaeger-all-in-one.yaml"

# Create routes for OpenShift
echo "Step 5: Creating OpenShift routes..."
oc create route edge jaeger-ui --service=jaeger-service --port=16686 -n jaeger-system || echo "Route already exists"

# Deploy using Helm charts
echo "Step 6: Installing Helm charts..."
cd "${PACKAGE_DIR}/charts"

# Install OpenTelemetry Collector
helm install otel-collector opentelemetry-collector-*.tgz \
  --namespace opentelemetry-system \
  --create-namespace \
  --set image.repository=otel/opentelemetry-collector-contrib \
  --set image.tag=0.88.0

# Install Prometheus stack with OpenShift-specific settings
helm install prometheus kube-prometheus-stack-*.tgz \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.image.tag=v2.47.2 \
  --set grafana.image.tag=10.2.0 \
  --set grafana.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP

# Create routes for monitoring services
echo "Step 7: Creating monitoring routes..."
oc create route edge grafana --service=prometheus-grafana --port=80 -n monitoring || echo "Grafana route already exists"
oc create route edge prometheus --service=prometheus-kube-prometheus-prometheus --port=9090 -n monitoring || echo "Prometheus route already exists"

echo "✓ OpenTelemetry deployment completed!"
echo
echo "OpenShift Access URLs:"
echo "- Jaeger UI: https://$(oc get route jaeger-ui -n jaeger-system -o jsonpath='{.spec.host}')"
echo "- Grafana: https://$(oc get route grafana -n monitoring -o jsonpath='{.spec.host}')"
echo "- Prometheus: https://$(oc get route prometheus -n monitoring -o jsonpath='{.spec.host}')"
echo
echo "Default Grafana credentials: admin/prom-operator"
EOF

    # Kubernetes deployment script (for non-OpenShift environments)
    cat > "${SCRIPTS_DIR}/deploy-otel-kubernetes.sh" << 'EOF'
#!/bin/bash
# Deploy OpenTelemetry stack in air-gapped Kubernetes environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenTelemetry Kubernetes Air-Gapped Deployment ==="

# Load images
echo "Step 1: Loading Docker images..."
bash "${SCRIPT_DIR}/load-images.sh"

# Install Helm if needed
echo "Step 2: Installing Helm if needed..."
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    cd /tmp
    tar -xzf "${PACKAGE_DIR}/binaries/helm-v3.13.3-linux-amd64.tar.gz"
    sudo mv linux-amd64/helm /usr/local/bin/
    sudo chmod +x /usr/local/bin/helm
fi

# Deploy OpenTelemetry Operator
echo "Step 3: Deploying OpenTelemetry Operator..."
kubectl apply -f "${PACKAGE_DIR}/manifests/otel-operator.yaml"

# Wait for operator to be ready
echo "Waiting for operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/opentelemetry-operator-controller-manager -n opentelemetry-operator-system

# Deploy Jaeger
echo "Step 4: Deploying Jaeger..."
kubectl apply -f "${PACKAGE_DIR}/manifests/jaeger-all-in-one.yaml"

# Deploy using Helm charts
echo "Step 5: Installing Helm charts..."
cd "${PACKAGE_DIR}/charts"

# Install OpenTelemetry Collector
helm install otel-collector opentelemetry-collector-*.tgz \
  --namespace opentelemetry-system \
  --create-namespace \
  --set image.repository=otel/opentelemetry-collector-contrib \
  --set image.tag=0.88.0

# Install Prometheus stack
helm install prometheus kube-prometheus-stack-*.tgz \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.image.tag=v2.47.2 \
  --set grafana.image.tag=10.2.0

echo "✓ OpenTelemetry deployment completed!"
echo
echo "Access URLs (use kubectl port-forward):"
echo "- Jaeger UI: kubectl port-forward -n jaeger-system svc/jaeger-service 16686:16686"
echo "- Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "- Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
EOF

    # Installation guide
    cat > "${SCRIPTS_DIR}/README.md" << 'EOF'
# OpenTelemetry Air-Gapped Deployment Guide

This package contains everything needed to deploy OpenTelemetry in an air-gapped Kubernetes environment.

## Package Contents

- `images/`: Docker images for all components
- `charts/`: Helm charts for deployment
- `manifests/`: Kubernetes YAML manifests
- `binaries/`: Required binaries (kubectl, helm, Go)
- `scripts/`: Deployment and utility scripts

## Prerequisites

- Kubernetes cluster (v1.24+)
- Docker runtime on all nodes
- Sufficient resources (4+ CPU cores, 8GB+ RAM)

## Deployment Steps

1. **Transfer the package** to your air-gapped environment
2. **Extract the package**: `tar -xzf otel-offline-package.tar.gz`
3. **Run deployment**: `cd otel-offline-package/scripts && bash deploy-otel.sh`

## Manual Steps (if needed)

### Load Images Manually
```bash
cd scripts
bash load-images.sh
```

### Deploy Components Individually
```bash
# Deploy operator
kubectl apply -f ../manifests/otel-operator.yaml

# Deploy Jaeger
kubectl apply -f ../manifests/jaeger-all-in-one.yaml

# Install with Helm
cd ../charts
helm install otel-collector opentelemetry-collector-*.tgz --namespace opentelemetry-system --create-namespace
```

## Verification

Check all pods are running:
```bash
kubectl get pods -A | grep -E "(otel|jaeger|prometheus|grafana)"
```

## Troubleshooting

- Check pod logs: `kubectl logs -n <namespace> <pod-name>`
- Verify images are loaded: `docker images | grep -E "(otel|jaeger|prometheus|grafana)"`
- Check service endpoints: `kubectl get svc -A`

## Configuration

Edit the collector configuration in `manifests/otel-collector-config.yaml` before deployment to customize:
- Receivers (OTLP, Prometheus, etc.)
- Processors (batch, memory_limiter, etc.)
- Exporters (Jaeger, Prometheus, etc.)
EOF

    chmod +x "${SCRIPTS_DIR}"/*.sh
    log_success "Deployment scripts created"
}

# Create package archive
create_package() {
    echo "Creating final package..."
    
    cd "${SCRIPT_DIR}"
    tar -czf "otel-offline-package.tar.gz" -C "${DOWNLOAD_DIR}" .
    
    echo "✓ Package created: otel-offline-package.tar.gz"
    echo "Package size: $(du -h otel-offline-package.tar.gz | cut -f1)"
}

# Main execution
main() {
    init_logging
    get_latest_versions
    check_prerequisites
    setup_directories
    
    # Rebuild IMAGES array with resolved versions
    build_images_array
    
    download_images
    download_charts
    download_binaries
    create_manifests
    create_deployment_scripts
    create_package
    
    log_success "Package Creation Complete!"
    echo
    echo "=== OpenTelemetry Offline Package Ready ==="
    echo "Package: otel-offline-package.tar.gz"
    echo "Size: $(du -h otel-offline-package.tar.gz | cut -f1)"
    echo
    echo "Transfer Instructions:"
    echo "1. Copy 'otel-offline-package.tar.gz' to your OpenShift environment"
    echo "2. Extract: tar -xzf otel-offline-package.tar.gz"
    echo "3. Deploy: cd otel-offline-package/scripts && bash deploy-otel-openshift.sh"
    echo
    echo "Package includes:"
    echo "- All Docker images for OTEL, Jaeger, Prometheus, Grafana"
    echo "- Helm charts for deployment"
    echo "- Kubernetes/OpenShift manifests"
    echo "- Go ${GO_VERSION}, Helm binaries (OpenShift-ready)"
    echo "- Complete deployment scripts"
    echo "- Configuration examples"
    echo
    echo "Logs available:"
    echo "- Download log: ${LOG_FILE}"
    echo "- Error log: ${ERROR_LOG}"
    
    # Show summary of any errors
    if [[ -s "${ERROR_LOG}" ]]; then
        echo
        echo "⚠️  Some errors occurred during download:"
        tail -5 "${ERROR_LOG}"
        echo "Check ${ERROR_LOG} for full error details"
    fi
}

# Run main function
main "$@"