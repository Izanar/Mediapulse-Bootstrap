#!/usr/bin/env bash
set -e

echo "===[MediaPulse Environment Setup]==="

# 1. Обновление пакетов
echo "[1/4] Updating packages"
sudo apt-get update -y && sudo apt-get upgrade -y

# 2. Установка базовых утилит
echo "[2/4] Installing core tools (curl, git, python3.12, pip, venv)..."
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

# 3. Проверка/Установка Docker
if ! command -v docker &> /dev/null; then
    echo "[3/4] Installing Docker Engine..."
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
    echo "[3/4] Docker is already installed"
fi

# 4. Проверка установленных версий
echo "[4/4] Verifying installations..."
echo "OS Version: $(lsb_release -ds)"
echo "Python Version: $(python3.12 --version)"
echo "Git Version: $(git --version)"
echo "Docker Version: $(docker --version || echo 'Docker service not running or permission needed')"

echo "=== Setup completed successfully! ==="