#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "🚀 [MediaPulse] Kind & Dev Environment Setup"
echo "=========================================="

if [[ ! -r /etc/os-release ]]; then
    echo "❌ Не удалось определить дистрибутив Linux."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" ]]; then
    echo "❌ Скрипт поддерживает Ubuntu и Debian; обнаружено: ${PRETTY_NAME:-unknown}."
    exit 1
fi

if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "aarch64" ]]; then
    echo "❌ Поддерживаются только архитектуры x86_64 и aarch64."
    exit 1
fi

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    if [[ ! "$expected" =~ ^[[:xdigit:]]{64}$ ]]; then
        echo "❌ Некорректный SHA-256: $expected"
        return 1
    fi
    printf '%s  %s\n' "$expected" "$file" | sha256sum --check --status
}

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
    amd64|arm64) ;;
    *)
        echo "❌ Неподдерживаемая архитектура dpkg: $ARCH."
        exit 1
        ;;
esac

# 1. Базовые зависимости
echo "[1/5] Updating package lists & installing base dependencies..."
sudo apt-get update -y
sudo apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    build-essential \
    gnupg \
    lsb-release \
    jq \
    unzip

# 2. GitHub CLI
echo "[2/5] Checking GitHub CLI..."
if ! has_cmd gh; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y gh
else
    echo "  -> GitHub CLI is already installed."
fi

# 3. Docker Engine
echo "[3/5] Checking Docker Engine..."
if ! has_cmd docker; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    echo "-> Docker installed! Note: You may need to restart WSL or run 'newgrp docker'."
else
    echo "  -> Docker Engine is already installed."
fi

# 4. Kubernetes tooling
echo "[4/5] Checking Kubernetes toolchain (with SHA-256 verification)..."

if ! has_cmd kubectl; then
    echo "  -> Installing kubectl..."
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    KUBECTL_TMP="$(mktemp)"
    trap 'rm -f "$KUBECTL_TMP"' EXIT
    curl -fsSL -o "$KUBECTL_TMP" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    KUBECTL_SHA256="$(curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256" | tr -d '[:space:]')"
    if ! verify_sha256 "$KUBECTL_TMP" "$KUBECTL_SHA256"; then
        echo "❌ Проверка SHA-256 для kubectl не пройдена."
        exit 1
    fi
    sudo install -m 0755 "$KUBECTL_TMP" /usr/local/bin/kubectl
    rm -f "$KUBECTL_TMP"
    trap - EXIT
else
    echo "  -> kubectl is already installed."
fi

if ! has_cmd kind; then
    echo "  -> Installing Kind..."
    KIND_VERSION="${KIND_VERSION:-v0.24.0}"
    KIND_TMP="$(mktemp)"
    trap 'rm -f "$KIND_TMP"' EXIT
    curl -fsSL -o "$KIND_TMP" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
    KIND_SHA256="$(curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}.sha256sum" | awk '{print $1}')"
    if ! verify_sha256 "$KIND_TMP" "$KIND_SHA256"; then
        echo "❌ Проверка SHA-256 для Kind не пройдена."
        exit 1
    fi
    sudo install -m 0755 "$KIND_TMP" /usr/local/bin/kind
    rm -f "$KIND_TMP"
    trap - EXIT
else
    echo "  -> Kind is already installed."
fi

if ! has_cmd helm; then
    echo "  -> Installing Helm..."
    # Официальный установщик Helm проверяет контрольные суммы самостоятельно.
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "  -> Helm is already installed."
fi

# 5. Summary
echo "------------------------------------------"
echo "[5/5] Environment Summary:"
echo "------------------------------------------"
echo "OS:           $(lsb_release -ds)"
echo "Architecture: ${ARCH}"
echo "Git:          $(git --version)"
echo "GitHub CLI:   $(gh --version | head -n 1)"
echo "Docker:       $(docker --version 2>/dev/null || echo 'Not running or permission required')"
echo "kubectl:      $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -n 1 || echo 'Installed')"
echo "Kind:         $(kind --version 2>/dev/null)"
echo "Helm:         $(helm version --short 2>/dev/null)"
echo "=========================================="
echo "🎉 Bootstrap completed successfully!"
