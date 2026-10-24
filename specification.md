# Technical Specification: MediaPulse Platform

## 1. Обзор системы (System Overview)
**MediaPulse** — это высоконагруженная отказоустойчивая микросервисная платформа для асинхронной обработки медиа-контента (инверсия цветов, масштабирование, оптимизация изображений) с поддержкой асинхронного REST API, распределенной очереди задач, S3-совместимого хранилища и автоматической доставки через GitOps.

---

## 2. Архитектура и стек технологий (Tech Stack)

Платформа MediaPulse построена на принципах разделения ответственности (Separation of Concerns) и состоит из 4 репозиториев:

1. **`mediapulse-bootstrap`** — Мета-репозиторий платформы. Содержит техническую спецификацию (`specification.md`), дорожную карту (`TODO.md`), конфигурации окружения разработки (`WSL-config`, `VS Code Workspace`), а также скрипты установки WSL2/SRE-инструментария (`setup.sh`).
2. **`mediapulse-app`** — Исходный код Python (FastAPI API, Celery Worker, SQLAlchemy/Alembic миграции, Dockerfiles, unit/integration тесты и CI-пайплайны GitHub Actions).
3. **`mediapulse-gitops`** — Декларативные Helm-чарты (с поддержкой Helm Hooks для миграций), окружения и ArgoCD Application манифесты для GitOps-деплоя в Kubernetes.
4. **`mediapulse-infra`** — Текущие конфигурации локального Kind-кластера и его GitOps-развертывания. Облачная инфраструктура как код на Terraform / Terragrunt (VPC, EKS/GKE, RDS PostgreSQL, Managed S3) запланирована, но ещё не реализована.

### 2.1 Back-end API & Worker
- **Язык программирования:** Python 3.12+
- **API Фреймворк:** FastAPI (AsyncIO, Pydantic v2)
- **Фоновое выполнение задач:** Celery
- **Брокер сообщений / Кэш:** Redis 7
- **Обработка изображений:** Pillow (PIL)

### 2.2 База данных и Хранилище
- **Основная СУБД:** PostgreSQL 16
- **ORM / Миграции:** SQLAlchemy 2.0 (asyncpg) + Alembic (автоматизация через Kubernetes Helm Hooks `pre-upgrade`)
- **Объектное хранилище (Object Storage):** Cloudflare R2 (S3-совместимый API, `boto3`)

### 2.3 Инфраструктура и GitOps
- **Контейнеризация:** Docker (Multi-stage builds)
- **Оркестрация:** Kubernetes (Kind локально; EKS/GKE рассматриваются для будущей облачной инфраструктуры)
- **Ingress Controller:** Traefik (локальный Kind-кластер)
- **GitOps CD:** ArgoCD
- **Пакетный менеджер проекта:** Helm 
- **IaC (Infrastructure as Code):** Terraform / Terragrunt (облачная инфраструктура запланирована)

### 2.4 Локальный доступ и секреты

Локальный кластер публикует сервисы на домене `izanar.dev` через Cloudflare Tunnel. Cloudflare Access защищает административные панели. Публичный HTTPS завершается на Cloudflare; соединение connector → Traefik внутри кластера использует HTTP. Внутренние сертификаты, cert-manager и внутренний CA не настроены. Подробный локальный сценарий и маршруты описаны в [каноническом README Mediapulse-Infra](../Mediapulse-Infra/README.md).

Для локального Kind секреты загружаются в Vault и передаются в Kubernetes через External Secrets Operator (ESO); секреты не хранятся в Git. Конфигурация Vault из локального сценария предназначена только для разработки и не является production-решением. Для production требуется отдельная защищённая конфигурация управления секретами.

---

## 3. Спецификация Функциональных Требований

### 3.1 Модуль Авторизации и Безопасности (Auth)
1. **Регистрация пользователей:** `POST /api/v1/auth/register` (Username + Password с хэшированием `bcrypt`).
2. **Аутентификация:** `POST /api/v1/auth/login` (Выдача JWT Access Token по стандарту OAuth2 Password Grant).
3. **Авторизация:** JWT-Bearer токен в заголовке `Authorization`.

### 3.2 Управление задачами (Task Management)
1. **Создание задачи:** `POST /api/v1/tasks/`
   - Авторизованный пользователь передает файл/параметры задачи.
   - Поддерживаются флаги доступа (`is_public`: `True`/`False`).
2. **Просмотр задачи:** `GET /api/v1/tasks/{task_id}`
   - Публичные задачи доступны всем.
   - Приватные задачи доступны только владельцу (`owner_id`).
3. **Статусы задач (`TaskStatus`):**
   - `PENDING` — задача создана и поставлена в очередь Redis.
   - `PROCESSING` — воркер Celery взял задачу в работу.
   - `COMPLETED` — обработка завершена, результат сохранен в S3.
   - `FAILED` — произошла ошибка при обработке.

### 3.3 Асинхронная обработка (Async Worker)
1. API сохраняет оригинал изображения в S3 bucket `media-originals`.
2. Задача публикуется в Redis Celery Queue.
3. Celery Worker вычитывает задачу, скачивает оригинал из S3, выполняет обработку Pillow (инверсия цвета).
4. Результат загружается в S3 bucket `media-processed`.
5. Статус записи `MediaTask` в БД обновляется на `COMPLETED`.

---

## 4. Нефункциональные требования (SRE & DevOps Standards)

1. **Scalability:** API и Celery Workers должны масштабироваться независимо (HPA в Kubernetes).
2. **Observability:** Healthcheck эндпоинты (`/health`, `/ready`), структурированные JSON-логи, метрики Prometheus.
3. **Security:**
   - Отсутствие открытых секретов в Git. Локально используется Vault + External Secrets Operator; production-решение управления секретами должно быть спроектировано отдельно и не должно полагаться на локальную конфигурацию Vault.
   - Запуск контейнеров от имени privileged-free пользователя (`non-root`).
4. **GitOps Workflow:**
   - Вся конфигурация K8s хранится декларативно в `mediapulse-gitops`.
   - Любые изменения в `main` автоматически синхронизируются ArgoCD.

---

## 5. Структура репозиториев (Repository Model)

```text
mediapulse/
├── mediapulse-bootstrap/ # specification.md, TODO.md, WSL2/Dev setup scripts, VS Code Workspace
├── mediapulse-app/       # Python code (FastAPI + Celery + Dockerfiles)
├── mediapulse-gitops/    # K8s manifests, Helm charts & ArgoCD Applications
└── mediapulse-infra/     # Локальный Kind-кластер; облачная Terraform/Terragrunt IaC запланирована