#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "☁️  [MediaPulse] GCP & IaC Tooling Setup"
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
echo "[1/7] Установка базовых зависимостей..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg jq lsb-release

# 2. Подключение репозитория Google Cloud
echo "[2/7] Подключение репозитория Google Cloud..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-cloud.gpg
sudo chmod a+r /etc/apt/keyrings/google-cloud.gpg
echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" |
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

# 3. Подключение репозитория HashiCorp
echo "[3/7] Подключение репозитория HashiCorp..."
if ! has_cmd terraform; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg |
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" |
        sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
fi

sudo apt-get update

# 4. Установка пакетов Google Cloud и IaC
echo "[4/7] Установка пакетов Google Cloud и IaC..."
packages=()
has_cmd gcloud || packages+=(google-cloud-cli)
has_cmd gke-gcloud-auth-plugin || packages+=(google-cloud-cli-gke-gcloud-auth-plugin)
has_cmd kubectl || packages+=(kubectl)
has_cmd terraform || packages+=(terraform)
if ((${#packages[@]})); then
    sudo apt-get install -y "${packages[@]}"
fi

# 5. Установка Helm
echo "[5/7] Установка Helm..."
if ! has_cmd helm; then
    echo "[5/7] Установка Helm..."
    helm_installer="$(mktemp)"
    trap 'rm -f "$helm_installer"' EXIT
    curl -fsSL -o "$helm_installer" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    bash "$helm_installer"
    rm -f "$helm_installer"
    trap - EXIT
else
    echo "[5/7] Helm уже установлен."
fi

# 6. Установка Terragrunt (GPG signature + SHA-256 verification)
echo "[6/7] Установка Terragrunt (GPG signature + SHA-256 verification)..."
if ! has_cmd terragrunt; then
    case "$(uname -m)" in
        x86_64) terragrunt_arch=amd64 ;;
        aarch64) terragrunt_arch=arm64 ;;
        *) echo "❌ Неподдерживаемая архитектура: $(uname -m)"; exit 1 ;;
    esac

    terragrunt_version="$(
        curl -fsSL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest |
            jq -er '.tag_name'
    )"

    TG_TMP="$(mktemp)"
    TG_SHA256SUMS="$(mktemp)"
    TG_SIG="$(mktemp)"
    TG_KEY="$(mktemp)"
    TG_GNUPGHOME="$(mktemp -d)"
    chmod 700 "$TG_GNUPGHOME"
    cleanup() {
        rm -f "$TG_TMP" "$TG_SHA256SUMS" "$TG_SIG" "$TG_KEY"
        rm -rf "$TG_GNUPGHOME"
    }
    trap cleanup EXIT

    curl -fsSL -o "$TG_TMP" \
        "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_${terragrunt_arch}"
    curl -fsSL -o "$TG_SHA256SUMS" \
        "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/SHA256SUMS"
    curl -fsSL -o "$TG_SIG" \
        "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/SHA256SUMS.gpgsig"
    curl -fsSL -o "$TG_KEY" \
        "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt-signing-key.asc"

    echo "  -> Проверка GPG-подписи SHA256SUMS..."
    if ! GNUPGHOME="$TG_GNUPGHOME" gpg --batch --import "$TG_KEY" >/dev/null 2>&1; then
        echo "❌ Не удалось импортировать GPG-ключ Terragrunt."
        exit 1
    fi
    if ! GNUPGHOME="$TG_GNUPGHOME" gpg --batch --verify "$TG_SIG" "$TG_SHA256SUMS" >/dev/null 2>&1; then
        echo "❌ GPG-подпись SHA256SUMS не прошла проверку."
        exit 1
    fi

    TG_EXPECTED_SHA256="$(awk -v f="terragrunt_linux_${terragrunt_arch}" '$2 == f {print $1; exit}' "$TG_SHA256SUMS")"
    if [[ -z "$TG_EXPECTED_SHA256" ]]; then
        echo "❌ Не найден SHA-256 для terragrunt_linux_${terragrunt_arch} в SHA256SUMS."
        exit 1
    fi
    if [[ ! "$TG_EXPECTED_SHA256" =~ ^[[:xdigit:]]{64}$ ]]; then
        echo "❌ Некорректный SHA-256: $TG_EXPECTED_SHA256"
        exit 1
    fi
    printf '%s  %s\n' "$TG_EXPECTED_SHA256" "$TG_TMP" | sha256sum --check --status || {
        echo "❌ Проверка SHA-256 для Terragrunt не пройдена."
        exit 1
    }

    chmod 0755 "$TG_TMP"
    sudo install -m 0755 "$TG_TMP" /usr/local/bin/terragrunt
    cleanup
    trap - EXIT
else
    echo "[6/7] Terragrunt уже установлен."
fi

# 7. Включение необходимых GCP API (требует gcloud auth login)
echo "[7/7] Проверка и включение необходимых GCP API..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "⚠️  Нет активной авторизации в gcloud. Пропускаем включение API."
    echo "    После 'gcloud auth login' запустите:"
    echo "    gcloud services enable container.googleapis.com compute.googleapis.com"
else
    ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
    if [[ -z "$ACTIVE_PROJECT" || "$ACTIVE_PROJECT" == "(unset)" ]]; then
        echo "⚠️  GCP проект не задан. Установите проект:"
        echo "    gcloud config set project PROJECT_ID"
        echo "    Затем повторите включение API:"
        echo "    gcloud services enable container.googleapis.com compute.googleapis.com"
    else
        echo "  -> Активный проект: $ACTIVE_PROJECT"
        echo "  -> Активный аккаунт: $(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)"
        gcloud services enable container.googleapis.com compute.googleapis.com
        echo "  ✅ GCP API включены: container.googleapis.com, compute.googleapis.com"
    fi
fi

echo "------------------------------------------"
echo "Проверка версий:"
gcloud --version | head -n 1
terraform --version | head -n 1
terragrunt --version
echo "kubectl: $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -n 1 || echo 'Installed')"
echo "GKE auth plugin: $(gke-gcloud-auth-plugin --version)"
echo "Helm: $(helm version --short)"
echo "=========================================="
echo "✅ Инструменты установлены."
echo "   Не забудьте: gcloud auth login  и  gcloud config set project PROJECT_ID"
echo "   Затем включите API: gcloud services enable container.googleapis.com compute.googleapis.com"
