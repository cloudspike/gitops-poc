#!/bin/bash
set -euo pipefail

# Default values
GITHUB_USER="cloudspike"
GITHUB_REPO="gitops-poc"
GITHUB_TOKEN=""
CLUSTER_NAME="flux-cluster"
FLUX_NAMESPACE="flux-system"

# Help message
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -u, --github-user USER    GitHub username (required)"
  echo "  -r, --github-repo REPO    GitHub repository name (required)"
  echo "  -t, --github-token TOKEN  GitHub personal access token (required)"
  echo "  -c, --cluster-name NAME   Kind cluster name (default: gitops-cluster)"
  echo "  -n, --namespace NS        Flux namespace (default: flux-system)"
  echo "  -h, --help                Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 -u myuser -r gitops -t ghp_token"
}

# Check if a parameter is provided
function check_param {
  if [ -z "$2" ]; then
    echo "Error: $1 is required"
    show_help
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -u|--github-user)
      GITHUB_USER="$2"
      shift 2
      ;;
    -r|--github-repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    -t|--github-token)
      GITHUB_TOKEN="$2"
      shift 2
      ;;
    -c|--cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -n|--namespace)
      FLUX_NAMESPACE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check required parameters
check_param "GitHub username" "$GITHUB_USER"
check_param "GitHub repository" "$GITHUB_REPO"
check_param "GitHub token" "$GITHUB_TOKEN"

# Check if required tools are installed
for cmd in kubectl flux; do
  if ! command -v $cmd &> /dev/null; then
    if [ "$cmd" = "flux" ]; then
      echo "Flux CLI not found. To install it:"
      echo "  macOS: brew install fluxcd/tap/flux"
      echo "  Linux: curl -s https://fluxcd.io/install.sh | sudo bash"
      exit 1
    else
      echo "Error: $cmd is not installed"
      exit 1
    fi
  fi
done

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Kind cluster '$CLUSTER_NAME' not found. Creating it first..."
  ./create-kind-cluster.sh --name "$CLUSTER_NAME"
fi

# Set kubectl context to the kind cluster
kubectl config use-context "kind-$CLUSTER_NAME"

echo "Bootstrap Flux on cluster '$CLUSTER_NAME'"

# Create GitHub deploy key for Flux
TMPKEY=$(mktemp -d)/flux-key
ssh-keygen -q -N "" -C "flux-${CLUSTER_NAME}" -t ed25519 -f "$TMPKEY"
PUB_KEY=$(cat "${TMPKEY}.pub")

# Add the deploy key to the GitHub repository
echo "Adding deploy key to GitHub repository..."
curl -s -X POST "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/keys" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"title\":\"Flux deploy key for ${CLUSTER_NAME}\",\"key\":\"${PUB_KEY}\",\"read_only\":true}"

echo "Checking Flux prerequisites"
flux check --pre
echo "Bootstrapping Flux on the cluster..."
flux bootstrap git \
  --url="ssh://git@github.com/${GITHUB_USER}/${GITHUB_REPO}" \
  --branch=main \
  --path="clusters/$CLUSTER_NAME" \
  --private-key-file="${TMPKEY}" \
  --namespace="$FLUX_NAMESPACE"

echo "Private key is stored in the cluster as a Kubernetes secret named flux-system in namespace $FLUX_NAMESPACE"
# Key rotation: https://fluxcd.io/flux/installation/bootstrap/generic-git-server/#ssh-private-key

# Clean up temporary files
rm -f "$TMPKEY" "${TMPKEY}.pub"

echo "Flux has been bootstrapped successfully!"
echo "To verify that Flux is running, execute: kubectl get pods -n ${FLUX_NAMESPACE}"
