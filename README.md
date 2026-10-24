# 🚀 MediaPulse Bootstrap & SRE Hub

<div align="center">

[![Docs](https://img.shields.io/badge/Docs-Specification%20%7C%20Roadmap-0077B6?style=for-the-badge&logo=readthedocs&logoColor=white)](specification.md)
[![Platform](https://img.shields.io/badge/Platform-WSL2%20%2F%20Ubuntu-blue?style=for-the-badge&logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![Setup](https://img.shields.io/badge/Setup-Bash%20%7C%20WSL2-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](setup.sh)
[![Tooling](https://img.shields.io/badge/Tooling-Docker%20%7C%20Kind%20%7C%20Helm-orange?style=for-the-badge&logo=docker&logoColor=white)](setup.sh)
[![Python](https://img.shields.io/badge/Python-3.12%2B-blue?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MPL%202.0-blue?style=for-the-badge)](LICENSE.md)

</div>

> Мета-репозиторий платформы **MediaPulse**. Содержит техническое задание, дорожную карту, конфигурации локального окружения и скрипты установки инструментов разработки.

---

## 📂 Структура репозитория

* **`specification.md`** — Детальная техническая спецификация системы и архитектурные требования.
* **`TODO.md`** — Актуальная доска задач и дорожная карта (Roadmap) проекта.
* **`setup.sh`** — Скрипт установки системных и SRE-инструментов в WSL2; не разворачивает Kubernetes-кластер.
* **`WSL-config`** — Рекомендуемая конфигурация ресурсов для WSL2.
* **`mediapulse.code-workspace`** — Конфигурация рабочего пространства VS Code для всех репозиториев платформы.
* **`Celery-run`** — Шпаргалка: команда запуска Celery-воркера из корня проекта.

---

## ⚙️ Быстрый старт (Установка инструментов)

Запустите скрипт в терминале WSL2, чтобы установить системные инструменты, включая Docker, kubectl, Kind, Helm, GitHub CLI и Terraform. Скрипт не создает кластер и не выполняет развертывание MediaPulse. Он создает `.venv` только если запущен в каталоге проекта, содержащем `requirements.txt` или `pyproject.toml`; зависимости устанавливаются только из `requirements.txt`, если этот файл есть.

```bash
chmod +x setup.sh
./setup.sh
```

Для создания локального кластера используйте каноническую инструкцию в [README репозитория Mediapulse-Infra](../Mediapulse-Infra/README.md): из каталога `Mediapulse-Infra/local/` выполните `make all-up`. Там же описаны доступ к сервисам и настройка Cloudflare Tunnel. Локальные сервисы доступны на домене `izanar.dev`; панели защищены Cloudflare Access. Публичный HTTPS завершается на Cloudflare, а соединение connector → Traefik внутри кластера использует HTTP; внутренние сертификаты и CA не настроены.
