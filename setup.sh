#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "🚀 [MediaPulse] SRE & Dev Environment Setup"
echo "=========================================="

# Вспомогательная функция проверки наличия команды
has_cmd() {
    command -v "$1" &> /dev/null
}

# 1. Обновление пакетов и базовые утилиты
echo "[1/7] Updating package lists & installing base dependencies..."
sudo apt-get update -y
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3.12 \
    python3.12-venv \
    python3-pip \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    unzip

# 2. GitHub CLI (gh)
if ! has_cmd gh; then
    echo "[2/7] Installing GitHub CLI (gh)..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install gh -y
else
    echo "[2/7] GitHub CLI is already installed."
fi

# 3. Docker Engine
if ! has_cmd docker; then
    echo "[3/7] Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    echo "-> Docker installed! Note: You may need to restart WSL or run 'newgrp docker'."
else
    echo "[3/7] Docker Engine is already installed."
fi

# 4. Kubernetes Tooling (kubectl, Kind, Helm)
echo "[4/7] Checking Kubernetes toolchain..."

if ! has_cmd kubectl; then
    echo "  -> Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
else
    echo "  -> kubectl is already installed."
fi

if ! has_cmd kind; then
    echo "  -> Installing Kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
else
    echo "  -> Kind is already installed."
fi

if ! has_cmd helm; then
    echo "  -> Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "  -> Helm is already installed."
fi

# 5. Infrastructure as Code (Terraform & Terragrunt)
echo "[5/7] Checking IaC toolchain (Terraform & Terragrunt)..."

if ! has_cmd terraform; then
    echo "  -> Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    sudo apt-get update -y && sudo apt-get install -y terraform
else
    echo "  -> Terraform is already installed."
fi

if ! has_cmd terragrunt; then
    echo "  -> Installing Terragrunt..."
    # В setup.sh для Terragrunt:
    TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name)
    curl -Lo /tmp/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64"
    chmod +x /tmp/terragrunt
    sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
else
    echo "  -> Terragrunt is already installed."
fi

# 6. Виртуальное окружение Python (только если вызов идет в папке с проектом)
echo "[6/7] Setting up Python venv..."
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    if [ ! -d ".venv" ]; then
        python3.12 -m venv .venv
    fi
    # shellcheck disable=SC1091
    source .venv/bin/activate
    pip install --upgrade pip --quiet
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt --quiet
        echo "  -> Dependencies installed into .venv."
    fi
else
    echo "  -> No requirements.txt found in current folder, skipping pip install."
fi

# 7. Финальная проверка версий
echo "------------------------------------------"
echo "[7/7] Environment Summary:"
echo "------------------------------------------"
echo "OS:           $(lsb_release -ds)"
echo "Python:       $(python3.12 --version)"
echo "Git:          $(git --version)"
echo "GitHub CLI:   $(gh --version | head -n 1)"
echo "Docker:       $(docker --version 2>/dev/null || echo 'Not running or permission required')"
echo "kubectl:      $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion || echo 'Installed')"
echo "Kind:         $(kind --version 2>/dev/null)"
echo "Helm:         $(helm version --short 2>/dev/null)"
echo "Terraform:    $(terraform --version | head -n 1 2>/dev/null)"
echo "Terragrunt:   $(terragrunt --version 2>/dev/null)"
echo "=========================================="
echo "🎉 Bootstrap completed successfully!"