#!/bin/bash
# =============================================================================
# Generate Helm values override files pointing to Harbor registry
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

OVERRIDES_DIR="${PROJECT_ROOT}/helm/harbor-overrides"

print_header "Generate Harbor Registry Override Values"

ensure_dirs "$OVERRIDES_DIR"

# Elasticsearch
cat >"${OVERRIDES_DIR}/elasticsearch-values.yaml" <<EOF
image:
  repository: ${HARBOR_ES_IMAGE}
  tag: "${ES_TAG}"
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: "${INGRESS_CLASS}"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
  - host: ${ELASTICSEARCH_INGRESS_HOST}
    paths:
    - path: /
      pathType: Prefix
EOF

# Filebeat
cat >"${OVERRIDES_DIR}/filebeat-values.yaml" <<EOF
image:
  repository: ${HARBOR_FILEBEAT_IMAGE}
  tag: "${FILEBEAT_TAG}"
  pullPolicy: IfNotPresent
EOF

# Kibana
cat >"${OVERRIDES_DIR}/kibana-values.yaml" <<EOF
image:
  repository: ${HARBOR_KIBANA_IMAGE}
  tag: "${KIBANA_TAG}"
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: "${INGRESS_CLASS}"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
  - host: ${KIBANA_INGRESS_HOST}
    paths:
    - path: /
      pathType: Prefix

dashboards:
  job:
    image: "${HARBOR_CURL_IMAGE}:${CURL_TAG}"
EOF

# Log Generator
cat >"${OVERRIDES_DIR}/log-generator-values.yaml" <<EOF
image:
  repository: ${HARBOR_LOG_GENERATOR_IMAGE}
  tag: "${LOG_GENERATOR_TAG}"
  pullPolicy: IfNotPresent
EOF

# Log Processor
cat >"${OVERRIDES_DIR}/log-processor-values.yaml" <<EOF
image:
  repository: ${HARBOR_LOG_PROCESSOR_IMAGE}
  tag: "${LOG_PROCESSOR_TAG}"
  pullPolicy: IfNotPresent
EOF

print_success "Override values generated in ${OVERRIDES_DIR}/"
ls -la "${OVERRIDES_DIR}/"
