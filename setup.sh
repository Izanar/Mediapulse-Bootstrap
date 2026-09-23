#!/usr/bin/env bash
set -e

echo "===[MediaPulse Environment Setup]==="

# 1. Обновление пакетов
echo "[1/6] Updating packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# 2. Установка базовых утилит
echo "[2/6] Installing core tools (curl, git, gh, python3.12, pip, venv)..."
sudo apt-get install -y \
  curl \
  git \
  gh \
  build-essential \
  python3.12 \
  python3.12-venv \
  python3-pip \
  ca-certificates \
  gnupg \
  lsb-release

# Добавление официального репозитория GitHub CLI
if ! command -v gh &> /dev/null; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp)
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install gh -y
fi

# 3. Проверка/Установка Docker
if ! command -v docker &> /dev/null; then
    echo "[3/6] Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "-> Docker installed! NOTE: You may need to restart WSL or run 'newgrp docker'."
else
    echo "[3/6] Docker is already installed"
fi

# 4. Проверка/Установка Kubernetes CLI (kubectl) & Kind
if ! command -v kubectl &> /dev/null || ! command -v kind &> /dev/null; then
    echo "[4/6] Installing kubectl and Kind..."
    
    # kubectl
    if ! command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi

    # Kind
    if ! command -v kind &> /dev/null; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
else
    echo "[4/6] kubectl and Kind are already installed"
fi

# 5. Проверка/Установка Helm
if ! command -v helm &> /dev/null; then
    echo "[5/6] Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "[5/6] Helm is already installed"
fi

# 6. Проверка установленных версий
echo "[6/6] Verifying installations..."
echo "OS Version: $(lsb_release -ds)"
echo "Python Version: $(python3.12 --version)"
echo "Git Version: $(git --version)"
echo "GitHub CLI Version: $(gh --version | head -n 1)"
echo "Docker Version: $(docker --version || echo 'Docker service not running or permission needed')"
echo "kubectl Version: $(kubectl version --client --output=yaml | grep gitVersion || echo 'kubectl installed')"
echo "Kind Version: $(kind --version)"
echo "Helm Version: $(helm version --short)"

echo "=== Setup completed successfully! ==="