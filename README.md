# 🚀 MediaPulse Bootstrap & SRE Hub

<div align="center">

[![Docs](https://img.shields.io/badge/Docs-Specification%20%7C%20Roadmap-0077B6?style=for-the-badge&logo=readthedocs&logoColor=white)](docs/specification.md)
[![Platform](https://img.shields.io/badge/Platform-WSL2%20%7C%20Ubuntu-blue?style=for-the-badge&logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![Setup](https://img.shields.io/badge/Setup-Bash%20%7C%20WSL2-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](Makefile)
[![Kind](https://img.shields.io/badge/Kind-Local%20K8s-000000?style=for-the-badge&logo=kubernetes&logoColor=white)](kind/setup-kind.sh)
[![kubectl](https://img.shields.io/badge/kubectl-K8s%20CLI-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](kind/setup-kind.sh)
[![Helm](https://img.shields.io/badge/Helm-Package%20Manager-0F1689?style=for-the-badge&logo=helm&logoColor=white)](kind/setup-kind.sh)
[![GCP](https://img.shields.io/badge/GCP-Google%20Cloud-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)](gcp/setup-gcp.sh)
[![GKE](https://img.shields.io/badge/GKE-Google%20Kubernetes-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)](gcp/setup-gcp.sh)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](gcp/setup-gcp.sh)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-Terraform%20Wrapper-7B42BC?style=for-the-badge)](gcp/setup-gcp.sh)
[![Python](https://img.shields.io/badge/Python-3.12%2B-blue?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MPL%202.0-blue?style=for-the-badge)](LICENSE.md)

</div>

> Мета-репозиторий платформы **MediaPulse**. Содержит техническую спецификацию, дорожную карту, конфигурации локального окружения и скрипты установки инструментов разработки.

---

## 📂 Структура репозитория

* **`docs/specification.md`** — Детальная техническая спецификация системы и архитектурные требования.
* **`docs/TODO.md`** — Актуальная доска задач и дорожная карта (Roadmap) проекта.
* **`kind/setup-kind.sh`** — Установка локального инструментария для разработки с Kind (Docker, GitHub CLI, kubectl, Kind, Helm, Python).
* **`gcp/setup-gcp.sh`** — Установка облачного/IaC-инструментария (Google Cloud CLI, Terraform, Terragrunt, `kubectl`, Helm, GKE auth plugin).
* **`Makefile`** — Команды `make make-kind` и `make make-gcp` для запуска установщиков.
* **`config/WSL-config`** — Рекомендуемая конфигурация ресурсов WSL2 (`.wslconfig`).
* **`config/Celery-run`** — Шпаргалка: команда запуска Celery-воркера из корня проекта `mediapulse-app`.
* **`config/mediapulse.code-workspace`** — Конфигурация рабочего пространства VS Code для всех репозиториев платформы.
* **`local-git/`** — Скрипты синхронизации и публикации всех четырёх репозиториев MediaPulse.
* **`LICENSE.md`** — Лицензия проекта (MPL-2.0).

---

## 🎯 Что устанавливается и где

| Инструмент | Назначение | Скрипт |
|------------|------------|--------|
| Docker | Контейнерная среда для Kind и локальных образов | `kind/setup-kind.sh` |
| GitHub CLI (`gh`) | Работа с репозиториями GitHub из терминала | `kind/setup-kind.sh` |
| kubectl | CLI управления Kubernetes (Kind, GKE, EKS) | оба скрипта |
| Kind | Локальный кластер Kubernetes в Docker (WSL2) | `kind/setup-kind.sh` |
| Helm | Пакетный менеджер Kubernetes (чарты, ArgoCD) | оба скрипта |
| Python 3.12 + venv | Среда для `mediapulse-app` | `kind/setup-kind.sh` |
| Google Cloud CLI (`gcloud`) | Управление ресурсами Google Cloud | `gcp/setup-gcp.sh` |
| GKE auth plugin | Аутентификация `kubectl` в GKE | `gcp/setup-gcp.sh` |
| Terraform | Инфраструктура как код (GCP/AWS) | `gcp/setup-gcp.sh` |
| Terragrunt | Обёртка над Terraform для окружений | `gcp/setup-gcp.sh` |

Никакой из скриптов **не создаёт** кластер, **не разворачивает** облачные ресурсы и **не выполняет** авторизацию в Google Cloud. После `make-gcp` войдите в GCP отдельно:

```bash
gcloud auth login
gcloud config set project PROJECT_ID
```

---

## ⚙️ Быстрый старт (Установка инструментов)

В WSL2/Ubuntu запустите нужный установщик из корня репозитория. Установка системных пакетов потребует `sudo`.

```bash
make make-kind   # локальный toolchain (Kind, kubectl, Helm, Docker, Python)
make make-gcp    # облачный/IaC toolchain (gcloud, Terraform, Terragrunt, GKE plugin)
```

`make-kind` устанавливает локальный toolchain и **не создаёт** кластер. Для создания локального кластера используйте каноническую инструкцию в [README репозитория Mediapulse-Infra](../Mediapulse-Infra/README.md): из каталога `Mediapulse-Infra/local/` выполните `make all-up`. Там же описаны доступ к сервисам и настройка Cloudflare Tunnel.

---

## ☁️ GCP / GKE (облачная инфраструктура)

Скрипт `gcp/setup-gcp.sh` подготавливает только инструменты. Облачная инфраструктура как код (VPC, GKE, RDS/Cloud SQL, buckets) планируется в репозитории `mediapulse-infra` (этап 5 дорожной карты, пока не реализована).

После установки:

1. Авторизуйтесь: `gcloud auth login`
2. Выберите проект: `gcloud config set project PROJECT_ID`
3. Для работы с GKE установите(auth plugin уже входит в `google-cloud-cli-gke-gcloud-auth-plugin`).

---

## 🔧 Примечания

* Локальный кластер, секреты (Vault + ESO) и GitOps-развёртывание описаны в `mediapulse-infra` и `mediapulse-gitops`; bootstrap-репозиторий не хранит секреты и не создаёт кластер.
* Если репозитории лежат рядом в каталоге `Mediapulse/`, используйте скрипты из `local-git/` для синхронизации всех четырёх репозиториев.
* Все скачиваемые бинарники (`kubectl`, `Kind`, `Terragrunt`) проверяются по контрольным суммам/GPG-подписям перед установкой.
