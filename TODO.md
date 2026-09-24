# MediaPulse — Project Roadmap & Task Board

> **Формат работы:** Micro-stepping (Шаг -> Проверка -> Следующий шаг).
> **Цель:** Production-grade SRE/DevOps архитектура (Python 3.12 + FastAPI + Celery + Kind + ArgoCD + Terraform).

---

## 🏗 Архитектура репозиториев
- [x] **mediapulse-bootstrap** — Мета-репозиторий платформы. Содержит Техническое Задание (`SPECIFICATION.md`), дорожную карту (`TODO.md`), конфигурации окружения разработки (`.wslconfig`, `VS Code Workspace`), а также скрипты первичной инициализации WSL2/SRE инструментария (`setup.sh`).
- [x] **mediapulse-app** — Исходный код API, Worker, Dockerfiles, CI.
- [ ] **mediapulse-gitops** — Helm-чарты, манифесты ArgoCD.
- [ ] **mediapulse-infra** — IaC (Terraform / Terragrunt под AWS/GCP).

---

## 📍 Этап 0: Подготовка локального окружения (WSL2 & VS Code)
- [x] 0.1. Проверка/установка Ubuntu 24.04 LTS в WSL2.
- [x] 0.2. Конфигурация `.wslconfig` (RAM / CPU ресурсы).
- [x] 0.3. Настройка VS Code и расширений.
- [x] 0.4. Проверка системных утилит (`git`, `python3.12`, `docker`).

---

## 📍 Этап 1: Разработка `mediapulse-app` (Локально)
- [x] 1.1. Инициализация структуры проекта и `.venv`.
- [x] 1.2. Базовый FastAPI (`main.py`, `config.py`, `/health` эндпоинт).
- [x] 1.3. Моделирование данных (`models.py` — модель `MediaTask`).
- [x] 1.4. База данных и миграции (PostgreSQL, SQLAlchemy 2.0 asyncpg, Alembic).
- [x] 1.5. Pydantic-схемы (`schemas.py`) и CRUD-операции (`crud.py`) для `MediaTask`.
- [x] 1.6. Роуты задач (`routers/tasks.py`) — создание и получение задач.
- [x] 1.7. Модуль авторизации (JWT, регистрация, вход, разграничение прав `is_public` / `private`).
- [x] 1.8. Фоновый воркер (Celery + Redis + Pillow) для инверсии цветов изображений.
- [x] 1.9. Интеграция MinIO / S3 для сохранения оригиналов и обработанных копий.
- [ ] **1.10. Галерея, Права доступа и Стандартизация (Ветка `feature/gallery-and-privacy`):**
  - [ ] Стандартизация именования файлов в S3 (единый паттерн с датой, UUID и суффиксами).
  - [ ] Эндпоинт и логика переключения видимости файлов (`is_public`: `true`/`false`).
  - [ ] Разработка галереи (API списка задач/файлов + UI/фронтенд для просмотра).
- [ ] 1.11. Упаковка в контейнеры (`Dockerfile.api` и `Dockerfile.worker` на `python:3.12-slim`).
- [ ] 1.12. Сквозное локальное тестирование всех эндпоинтов.

---

## 📍 Этап 2: CI/CD и публикация в GHCR
- [ ] 2.1. Создание GitHub-репозитория `mediapulse-app` и настройка secrets/tokens.
- [ ] 2.2. Написание CI-пайплайна `.github/workflows/ci.yml`.
- [ ] 2.3. Пуш кода, сборка и публикация контейнерных образов в GHCR.

---

## 📍 Этап 3: Локальный Kubernetes (Kind)
- [ ] 3.1. Установка `kubectl` и `kind` в WSL2.
- [ ] 3.2. Создание конфига `kind-config.yaml` (1 Master + 3 Workers) и запуск HA-кластера.
- [ ] 3.3. Установка и настройка NGINX Ingress Controller.

---

## 📍 Этап 4: GitOps & Helm (`mediapulse-gitops`)
- [ ] 4.1. Разворачивание ArgoCD внутри Kind.
- [ ] 4.2. Создание Helm-чартов (Postgres, Redis, MinIO, API, Worker).
- [ ] 4.3. Настройка ArgoCD Application деклараций и проверка авто-деплоя.

---

## 📍 Этап 5: Облачная инфраструктура (`mediapulse-infra`)
- [ ] 5.1. Проектирование структуры модулей Terraform/Terragrunt.
- [ ] 5.2. Написание манифестов (VPC, EKS, RDS, S3).
- [ ] 5.3. Выполнение `terraform plan` и тестовый деплой в облако.