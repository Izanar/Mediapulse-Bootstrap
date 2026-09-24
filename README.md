# 🚀 MediaPulse Bootstrap & SRE Hub

<div align="center">

[![Platform](https://img.shields.io/badge/Platform-WSL2%20%2F%20Ubuntu-blue?style=for-the-badge&logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![DevOps](https://img.shields.io/badge/DevOps-Docker%20%7C%20Kind%20%7C%20Helm-orange?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-red?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

> Мета-репозиторий платформы **MediaPulse**. Содержит единое техническое задание, дорожную карту проекта, конфигурации локального окружения и скрипты автоматической инициализации инфраструктуры.

---

## 📂 Структура репозитория

* **`SPECIFICATION.md`** — Детальная техническая спецификация системы и архитектурные требования.
* **`TODO.md`** — Актуальная доска задач и дорожная карта (Roadmap) проекта.
* **`setup.sh`** — Скрипт автоматического развертывания рабочего окружения и SRE-инструментов в WSL2.
* **`.wslconfig`** — Рекомендуемая конфигурация ресурсов для WSL2.

---

## ⚙️ Быстрый старт (Инициализация окружения)

Чтобы развернуть системные утилиты (Docker, kubectl, Kind, Helm, GitHub CLI) и настроить виртуальное окружение Python, выполните скрипт инициализации в терминале WSL2:

```bash
chmod +x setup.sh
./setup.sh
