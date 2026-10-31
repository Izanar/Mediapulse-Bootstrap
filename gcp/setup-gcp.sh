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

echo "[1/6] Установка базовых зависимостей..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg jq lsb-release
sudo install -m 0755 -d /etc/apt/keyrings

echo "[2/6] Подключение репозитория Google Cloud..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-cloud.gpg
sudo chmod a+r /etc/apt/keyrings/google-cloud.gpg
echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" |
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

if ! has_cmd terraform; then
    echo "[3/6] Подключение репозитория HashiCorp..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg |
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" |
        sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
fi

echo "[4/6] Установка пакетов Google Cloud и IaC..."
sudo apt-get update
packages=()
has_cmd gcloud || packages+=(google-cloud-cli)
has_cmd gke-gcloud-auth-plugin || packages+=(google-cloud-cli-gke-gcloud-auth-plugin)
has_cmd kubectl || packages+=(kubectl)
has_cmd terraform || packages+=(terraform)
if ((${#packages[@]})); then
    sudo apt-get install -y "${packages[@]}"
fi

if ! has_cmd helm; then
    echo "[5/6] Установка Helm..."
    helm_installer="$(mktemp)"
    trap 'rm -f "$helm_installer"' EXIT
    curl -fsSL -o "$helm_installer" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    bash "$helm_installer"
    rm -f "$helm_installer"
    trap - EXIT
else
    echo "[5/6] Helm уже установлен."
fi

if ! has_cmd terragrunt; then
    echo "[6/6] Установка Terragrunt (GPG signature + SHA-256 verification)..."
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

    curl -fsSL -o "$TG_TMP"         "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_${terragrunt_arch}"
    curl -fsSL -o "$TG_SHA256SUMS"         "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/SHA256SUMS"
    curl -fsSL -o "$TG_SIG"         "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/SHA256SUMS.gpgsig"
    curl -fsSL -o "$TG_KEY"         "https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt-signing-key.asc"

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
    printf '%s  %s
' "$TG_EXPECTED_SHA256" "$TG_TMP" | sha256sum --check --status || {
        echo "❌ Проверка SHA-256 для Terragrunt не пройдена."
        exit 1
    }

    chmod 0755 "$TG_TMP"
    sudo install -m 0755 "$TG_TMP" /usr/local/bin/terragrunt
    cleanup
    trap - EXIT
else
    echo "[6/6] Terragrunt уже установлен."
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
echo "✅ Инструменты установлены. Авторизуйтесь отдельно: gcloud auth login"
