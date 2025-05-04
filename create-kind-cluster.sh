#!/bin/bash
set -euo pipefail

# Default values
CLUSTER_NAME="gitops-cluster"
WAIT_TIME=120

# Help message
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -n, --name NAME       Set cluster name (default: gitops-cluster)"
  echo "  -w, --wait SECONDS    Wait time for cluster to be ready (default: 120)"
  echo "  -h, --help            Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 --name my-cluster"
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -n|--name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -w|--wait)
      WAIT_TIME="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Check if required tools are installed
for cmd in kind kubectl; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed"
    exit 1
  fi
done

echo "Creating kind cluster '$CLUSTER_NAME'"

kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml

echo "Waiting for cluster to be ready (up to $WAIT_TIME seconds)..."
kubectl wait --for=condition=Ready nodes --all --timeout="${WAIT_TIME}s"

#echo "Setting kubectl context to kind-$CLUSTER_NAME"
#kubectl config use-context "kind-$CLUSTER_NAME"

#echo "Installing metrics-server..."
#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
#kubectl patch -n kube-system deployment metrics-server --type=json \
#  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "Cluster '$CLUSTER_NAME' is ready!"
echo "To delete this cluster later, run: kind delete cluster --name $CLUSTER_NAME"
