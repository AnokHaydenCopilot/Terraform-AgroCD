# Terraform GCP: GKE Кластер та CI/CD Пайплайн з Cloud Build та GitHub

Цей проект демонструє створення інфраструктури в Google Cloud Platform (GCP) за допомогою Terraform, включаючи:
*   Регіональний кластер Google Kubernetes Engine (GKE).
*   CI/CD пайплайн, що використовує Google Cloud Build, інтегрований з GitHub репозиторієм для автоматичної збірки Docker-образів та їх розгортання в GKE.
*   GCS Бакет для зберігання стану Terraform (рекомендовано).

## Архітектура та компоненти

1.  **Terraform Конфігурація:**
    *   Знаходиться в директорії `environments/terraform/`.
    *   Керує створенням всіх GCP ресурсів.
    *   Використовує сервісний акаунт GCP для автентифікації (ключ зберігається в `service-account-key.json` на рівень вище директорії `environments/`).

2.  **Google Kubernetes Engine (GKE) Кластер:**
    *   **Тип:** Регіональний.
    *   **Регіон:** `us-central1`.
    *   **Зони:** Вузли розподілені по зонах `us-central1-a`, `us-central1-b`, `us-central1-c` (за замовчуванням для регіональних кластерів).
    *   **Пули вузлів:** Один пул вузлів з наступними характеристиками для кожного вузла:
        *   **Кількість вузлів:** Налаштовується (у нашому прикладі було 2, по одному на кожну з активних зон, якщо їх 2, або відповідно до `node_count`).
        *   **Тип машини:** `e2-micro`.
        *   **Тип диска:** `pd-balanced`.
        *   **Розмір диска:** 20 ГБ (мінімум 12 ГБ потрібно для образу ОС).
    *   Автоматичне відновлення та оновлення вузлів увімкнено.

3.  **Google Cloud Storage (GCS) Бакет для стану Terraform:**
    *   Для зберігання файлу стану Terraform (`terraform.tfstate`) у безпечному та спільному місці.
    *   Налаштовується через файл `backend.tf` всередині директорії `environments/terraform/`.
    *   Цей бакет має бути створений **перед** першим запуском `terraform init` з конфігурацією бекенду.

4.  **CI/CD Пайплайн з Google Cloud Build та GitHub:**
    *   **Джерело коду:** GitHub репозиторій (`AnokHaydenCopilot/Terraform-Study`).
    *   **Тригер:** Cloud Build тригер, налаштований на спрацювання при подіях `push` у вказану гілку (наприклад, `main`) GitHub репозиторію. Тригер активується при змінах у директорії `gcp-terraform-project/source_code_for_pipeline/`.
    *   **Файл конфігурації Cloud Build:** `gcp-terraform-project/source_code_for_pipeline/cloudbuild.yaml`. Цей файл визначає кроки пайплайну.
    *   **Процес пайплайну:**
        1.  **Збірка Docker-образу:** Використовується `Dockerfile` з директорії `gcp-terraform-project/source_code_for_pipeline/app/` для збірки Docker-образу простого веб-додатку.
        2.  **Публікація образу:** Зібраний Docker-образ публікується в Google Container Registry (GCR).
        3.  **Розгортання в GKE:**
            *   Отримуються облікові дані для доступу до GKE кластера.
            *   Оновлюється Kubernetes маніфест (`gcp-terraform-project/source_code_for_pipeline/kubernetes/deployment.yaml`) актуальним тегом Docker-образу.
            *   Оновлений маніфест застосовується до GKE кластера за допомогою `kubectl apply`.
            *   Створюється/оновлюється Kubernetes Deployment та Service (типу LoadBalancer) для доступу до додатку.
    *   **Сервісний акаунт для виконання білдів:** Використовується сервісний акаунт, вказаний у Terraform (ваш "Owner" SA), якому надані необхідні дозволи для взаємодії з GCR та GKE. Налаштування логування для білду (`CLOUD_LOGGING_ONLY`) вказано в `cloudbuild.yaml`.

5.  **Приклад Додатку:**
    *   Простий веб-сервер на базі Nginx, що відображає статичну HTML-сторінку (`index.html`).
    *   Знаходиться в `gcp-terraform-project/source_code_for_pipeline/app/`.

## Структура проекту
gcp-terraform-project/ <- Корінь GitHub репозиторію
├── environments/
│ └── terraform/ <- Terraform код для інфраструктури
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── backend.tf 
├── source_code_for_pipeline/ <- Код та конфігурації для CI/CD пайплайну
│ ├── app/ <- Код простого веб-додатку
│ │ ├── Dockerfile
│ │ └── index.html
│ ├── kubernetes/ <- Kubernetes маніфести
│ │ └── deployment.yaml
│ └── cloudbuild.yaml <- Конфігурація для Google Cloud Build
└── service-account-key.json <- (ПОЗА РЕПОЗИТОРІЄМ!) Ключ сервісного акаунту GCP

**Важливо:** Файл `service-account-key.json` НІКОЛИ не повинен зберігатися у публічному (і навіть приватному, якщо це можливо) Git репозиторії. Він має бути доступний локально для Terraform під час виконання `apply`. Шлях до нього в конфігурації провайдера: `file("${path.module}/../../service-account-key.json")` (припускаючи, що він лежить на два рівні вище від директорії `environments/terraform/`).

## Вимоги

*   Акаунт Google Cloud Platform з увімкненим білінгом.
*   Встановлений Terraform CLI.
*   Встановлений `gcloud` CLI (Google Cloud SDK).
*   Ключ сервісного акаунту GCP з необхідними дозволами (рекомендовано роль "Owner" для простоти на етапі розробки, або більш гранулярні ролі для production).
*   GitHub репозиторій.
*   Налаштоване підключення Cloud Build до GitHub репозиторію через Cloud Build GitHub App.

## Налаштування та Запуск

## Налаштування та Запуск

1.  **Клонуйте репозиторій (якщо потрібно).**
2.  **Розмістіть файл `service-account-key.json`** у відповідному місці (наприклад, у корені `gcp-terraform-project/`, тоді шлях у провайдері буде `file("${path.module}/../service-account-key.json")`, або на два рівні вище від `environments/terraform/`). **НЕ КОМІТЬТЕ ЦЕЙ ФАЙЛ!**
3.  **Налаштуйте GCS Бакет для стану Terraform:**
    *   Створіть GCS бакет вручну (наприклад, через `gsutil mb gs://your-unique-tfstate-bucket-name`).
    *   Увімкніть версіонування для цього бакету.
    *   Відредагуйте файл `environments/terraform/backend.tf`, вказавши назву вашого бакету.
4.  **Підключіть ваш GitHub репозиторій до Google Cloud Build:**
    *   **Підключення до GitHub:** Google Cloud Build підключений до GitHub репозиторію (`AnokHaydenCopilot/Terraform-Study`) за допомогою Cloud Build GitHub App.
    *   **Джерело коду:** GitHub репозиторій.
    *   Перейдіть в GCP Console -> Cloud Build -> Settings.
    *   Знайдіть секцію "Source repositories" (або "Host connections" / "Repository connections").
    *   Натисніть "Connect host" або "Connect repository".
    *   Оберіть "GitHub (Cloud Build GitHub App)" як провайдера.
    *   Пройдіть процес автентифікації з GitHub, встановіть Cloud Build GitHub App на ваш акаунт/організацію та надайте доступ до вашого репозиторію (`AnokHaydenCopilot/Terraform-Study`).
    *   Завершіть підключення в GCP Console.
5.  **Ініціалізація Terraform:**
    Перейдіть в директорію `environments/terraform/` та виконайте:
    ```bash
    terraform init
    ```
6.  **Перевірка та Застосування конфігурації Terraform:**
    ```bash
    terraform validate
    terraform plan -var="project_id=your-gcp-project-id"
    terraform apply -var="project_id=your-gcp-project-id"
    ```
    Замініть `your-gcp-project-id` на ваш реальний ID проекту.
7.  **Тестування CI/CD Пайплайну:**
    *   Внесіть зміни у файли всередині директорії `gcp-terraform-project/source_code_for_pipeline/` (наприклад, в `app/index.html`).
    *   Закомітьте та запуште зміни у гілку, на яку налаштований Cloud Build тригер (наприклад, `main`).
    *   Перевірте історію збірок в Cloud Build та стан розгортання в GKE.