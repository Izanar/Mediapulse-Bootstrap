# 🚀 MediaPulse Bootstrap & SRE Hub

<div align="center">

[![Docs](https://img.shields.io/badge/Docs-Specification%20%7C%20Roadmap-0077B6?style=for-the-badge&logo=readthedocs&logoColor=white)](specification.md)
[![Platform](https://img.shields.io/badge/Platform-WSL2%20%2F%20Ubuntu-blue?style=for-the-badge&logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![Setup](https://img.shields.io/badge/Setup-Bash%20%7C%20WSL2-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](setup.sh)
[![Tooling](https://img.shields.io/badge/Tooling-Docker%20%7C%20Kind%20%7C%20Helm-orange?style=for-the-badge&logo=docker&logoColor=white)](setup.sh)
[![Python](https://img.shields.io/badge/Python-3.12%2B-blue?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MPL%202.0-blue?style=for-the-badge)](LICENSE.md)

</div>

> Мета-репозиторий платформы **MediaPulse**. Содержит единое техническое задание, дорожную карту проекта, конфигурации локального окружения и скрипты автоматической инициализации инфраструктуры.

---

## 📂 Структура репозитория

* **`specification.md`** — Детальная техническая спецификация системы и архитектурные требования.
* **`TODO.md`** — Актуальная доска задач и дорожная карта (Roadmap) проекта.
* **`setup.sh`** — Скрипт автоматического развертывания рабочего окружения и SRE-инструментов в WSL2.
* **`WSL-config`** — Рекомендуемая конфигурация ресурсов для WSL2.
* **`mediapulse.code-workspace`** — Конфигурация рабочего пространства VS Code для всех репозиториев платформы.
* **`Celery-run`** — Шпаргалка: команда запуска Celery-воркера из корня проекта.

---

## ⚙️ Быстрый старт (Инициализация окружения)

Чтобы развернуть системные утилиты (Docker, kubectl, Kind, Helm, GitHub CLI) и настроить виртуальное окружение Python, выполните скрипт инициализации в терминале WSL2:

```bash
chmod +x setup.sh
./setup.sh
```
