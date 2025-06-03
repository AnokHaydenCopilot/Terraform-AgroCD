# Terraform GCP: GKE Кластер з Custom VPC, CI/CD через Cloud Build та Моніторинг з Prometheus/Grafana

Цей проект демонструє створення комплексної інфраструктури в Google Cloud Platform (GCP) за допомогою Terraform. Він включає:

*   **Google Kubernetes Engine (GKE) Кластер:** Регіональний кластер GKE, розгорнутий у кастомній VPC.
*   **Кастомну VPC Мережу:** Спеціальна Virtual Private Cloud (VPC) мережа з підмережею для GKE.
*   **Кастомний Пул Вузлів GKE:** Налаштовуваний пул вузлів для GKE.
*   **Правила Брандмауера:** Налаштування правил для внутрішнього трафіку, доступу через IAP (SSH) та для балансувальників навантаження GCP (Health Checks).
*   **CI/CD Пайплайн:** Використовує Google Cloud Build, інтегрований з GitHub репозиторієм для автоматичної збірки Docker-образів та їх розгортання в GKE.
*   **Моніторинг:** Розгортання стеку Prometheus та Grafana за допомогою Helm для моніторингу кластера.
*   **Управління API:** Явне ввімкнення необхідних GCP сервісів.

## Ключові Компоненти та Архітектура

1.  **Terraform Конфігурація:**
    *   Знаходиться в директорії `environments/dev/`.
    *   Керує створенням всіх GCP ресурсів.
    *   Використовує сервісний акаунт GCP для автентифікації (ключ, вказаний у `variables.tf` як `../../kubernetes-root.json`, що означає його розміщення у корені проекту `gcp-terraform-project/`).

2.  **Мережева Інфраструктура:**
    *   **Custom VPC:** `google_compute_network.custom_vpc` (стандартна назва: "gke-custom-vpc").
    *   **GKE Subnet:** `google_compute_subnetwork.gke_subnet` (стандартна назва: "gke-primary-subnet") з основним CIDR ("10.10.0.0/20") та вторинними діапазонами для Pods (назва "gke-pods-range", CIDR "10.20.0.0/16") та Services (назва "gke-services-range", CIDR "10.30.0.0/20").
    *   **Firewall Rules:**
        *   `allow_internal_gke_subnet`: Дозволяє весь трафік всередині GKE підмережі, подів та сервісів.
        *   `allow_ssh_iap_to_gke_nodes`: Дозволяє SSH доступ до вузлів GKE через IAP.
        *   `allow_gclb_health_checks_to_gke_nodes`: Дозволяє перевірки стану від балансувальників навантаження Google.

3.  **Google Kubernetes Engine (GKE) Кластер:**
    *   **Ресурс:** `google_container_cluster.primary` (стандартна назва: "tf-demo-cluster").
    *   **Тип:** Регіональний (стандартна локація: "us-central1").
    *   **Мережа:** Використовує створену кастомну VPC та підмережу.
    *   **IP Allocation Policy:** Використовує вторинні діапазони підмережі для подів та сервісів.
    *   **Дефолтний пул вузлів видалено.**

4.  **GKE Пул Вузлів:**
    *   **Ресурс:** `google_container_node_pool.primary_nodes`.
    *   **Кількість вузлів:** 1.
    *   **Тип машини:** "e2-medium".
    *   **Тип та розмір диска:** "pd-balanced", 20 ГБ.
    *   **OAuth Scopes:** `https://www.googleapis.com/auth/cloud-platform` для повного доступу до GCP API.
    *   **Теги:** "gke-node" (стандартний тег для вузлів) та "tf-demo-cluster" (назва кластера).
    *   Автоматичне відновлення та оновлення увімкнено.

5.  **CI/CD Пайплайн (Google Cloud Build та GitHub):**
    *   **Тригер:** `google_cloudbuild_trigger.github_pipeline_trigger` (назва `tf-github-update`).
    *   **Джерело коду:** GitHub репозиторій `AnokHaydenCopilot/Terraform-Study`.
    *   **Умова спрацювання:** Push в гілку `main` при змінах у `gcp-terraform-project/source_code_for_pipeline/**`.
    *   **Файл конфігурації Cloud Build:** `gcp-terraform-project/source_code_for_pipeline/cloudbuild.yaml`.
    *   **Підстановки для Cloud Build:**
        *   `_GKE_CLUSTER_NAME`: "tf-demo-cluster" (назва GKE кластера)
        *   `_GKE_LOCATION`: "us-central1" (локація GKE кластера)
        *   `_IMAGE_NAME`: "my-simple-gke-app" (назва образу для пайплайну)
    *   **Процес пайплайну (визначається в `cloudbuild.yaml`):**
        1.  Збірка Docker-образу (з `source_code_for_pipeline/app/Dockerfile`).
        2.  Публікація образу в Google Container Registry (GCR) або Artifact Registry.
        3.  Розгортання/оновлення додатку в GKE (застосування `source_code_for_pipeline/kubernetes/deployment.yaml`).
    *   **Сервісний акаунт для білдів:** Використовується той самий сервісний акаунт, що й для Terraform (визначений з `kubernetes-root.json`).

6.  **Моніторинг (Prometheus & Grafana):**
    *   **Ресурс:** `helm_release.prometheus_stack`.
    *   **Чарт:** `kube-prometheus-stack` з репозиторію `prometheus-community`.
    *   **Неймспейс:** `monitoring` (створюється автоматично).
    *   **Пароль адміністратора Grafana:** Стандартний пароль "YourSecurePassword123!" (рекомендується змінити!).
    *   **Сервіс Grafana:** Типу `LoadBalancer` для зовнішнього доступу.

7.  **Управління API GCP:**
    *   Численні ресурси `google_project_service` для активації необхідних API (Container, Cloud Build, GCR, IAM, Compute тощо).

## Структура Проекту

```
gcp-terraform-project/
├── kubernetes-root.json # Ключ Сервісного Акаунту GCP (шлях вказаний у variables.tf)
├── service-account-key.json # (Може бути тим самим файлом, або для інших цілей)
│
├── environments/
│ └── dev/ # Terraform код для інфраструктури
│ ├── main.tf 
│ ├── variables.tf 
│ ├── outputs.tf 
│ ├── backend.tf 
│ ├── .terraform.lock.hcl
│ └── ... # Інші файли Terraform, логи, стан (.terraform/)
│
└── source_code_for_pipeline/ # Код та конфігурації для CI/CD пайплайну
├── app/ # Приклад простого веб-додатку
│ ├── Dockerfile
│ └── index.html
├── kubernetes/ # Kubernetes маніфести для додатку
│ └── deployment.yaml
└── cloudbuild.yaml # Конфігурація для Google Cloud Build
```
**Важливо:** Файл `kubernetes-root.json` (та будь-які інші файли ключів) **НІКОЛИ** не повинен зберігатися у публічному Git репозиторії. Додайте його до `.gitignore`.

## Вимоги

*   Акаунт Google Cloud Platform з увімкненим білінгом.
*   Встановлений **Terraform CLI**.
*   Встановлений **Helm CLI**.
*   **Ключ сервісного акаунту GCP (`kubernetes-root.json`)** з необхідними дозволами (наприклад, `Owner` для розробки, або більш гранулярні ролі для production).
*   GitHub репозиторій.
*   Налаштоване підключення Cloud Build до вашого GitHub репозиторію.

## Налаштування та Запуск

1.  **Клонуйте Репозиторій:**
    ```bash
    git clone https://github.com/AnokHaydenCopilot/Terraform-Study.git
    cd Terraform-Study/gcp-terraform-project
    ```

2.  **Встановіть Необхідні Інструменти:**
    *   **Terraform:** [Інструкція з встановлення](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    *   **Helm:** [Інструкція з встановлення](https://helm.sh/docs/intro/install/)
        ```bash
        # Приклад для Windows з Winget
        winget install Helm.Helm
        ```   

3.  **Налаштування Сервісного Акаунту GCP:**
    *   В консолі GCP (IAM & Admin -> Service Accounts) створіть сервісний акаунт.
    *   Надайте йому необхідні ролі (наприклад, `Owner` для простоти на етапі розробки).
    *   Завантажте ключ для цього сервісного акаунту у форматі JSON.
    *   Перейменуйте завантажений файл на `kubernetes-root.json` та розмістіть його в кореневій папці проекту (`gcp-terraform-project/kubernetes-root.json`). Шлях до цього файлу (`../../kubernetes-root.json`) вже вказаний як стандартне значення для змінної `service_account_key_path` у файлі `environments/dev/variables.tf`.
    *   **ВАЖЛИВО:** Додайте `kubernetes-root.json` до вашого файлу `.gitignore`, щоб випадково не закомітити його.
        ```
        # .gitignore
        kubernetes-root.json
        *.log
        .terraform/
        terraform.tfstate
        terraform.tfstate.backup
        ```

4.  **Конфігурація Змінних Terraform:**
    *   Відкрийте файл `environments/dev/variables.tf`.
    *   Для змінної `grafana_admin_password` встановлено стандартне значення "YourSecurePassword123!". **Настійно рекомендується змінити його на унікальний та надійний пароль.**
    *   Для змінної `project_id` встановлено стандартне значення "focused-ion-452816-h5". Змініть його на Ваш.
    *   Перегляньте інші змінні (наприклад, `region` зі стандартним значенням "us-central1")

5.  **(Рекомендовано) Налаштування GCS Бекенду для Зберігання Стану Terraform:**
    *   Створіть GCS бакет вручну в GCP (наприклад, через консоль або `gsutil mb gs://your-unique-tfstate-bucket-name`).
    *   Відредагуйте файл `environments/dev/backend.tf`, вказавши назву вашого бакету:
        ```terraform
        # environments/dev/backend.tf
        terraform {
          backend "gcs" {
            bucket  = "your-unique-tfstate-bucket-name"  # Змініть на ваш бакет
            prefix  = "kubernetes-cluster-pipeline/state"    
          }
        }
        ```

6.  **Підключення GitHub Репозиторію до Google Cloud Build:**
    *   Перейдіть до Google Cloud Console -> Cloud Build -> Settings.
    *   Знайдіть секцію "Source repositories" (або "Host connections" / "Repository connections").
    *   Натисніть "Connect host" або "Connect repository".
    *   Оберіть "GitHub (Cloud Build GitHub App)" як провайдера.
    *   Пройдіть процес автентифікації з GitHub, встановіть Cloud Build GitHub App на ваш акаунт/організацію та надайте доступ до вашого репозиторію (`AnokHaydenCopilot/Terraform-Study` або вашого форку).
    *   Завершіть підключення в GCP Console. (Terraform створить сам тригер, але з'єднання має існувати).

7.  **Ініціалізація Terraform:**
    Перейдіть в директорію з Terraform кодом:
    ```bash
    cd environments/dev/
    terraform init
    ```

8.  **Перевірка та Застосування Конфігурації Terraform:**
    Ви можете передати значення змінних через командний рядок, щоб перекрити стандартні значення з `variables.tf`.
    ```bash
    # (Опціонально) Перевірка плану.
    terraform plan -var="project_id=your-gcp-project-id" -var="grafana_admin_password=YourActualGrafanaPassword123!"

    # Застосування конфігурації.
    terraform apply -var="project_id=your-gcp-project-id" -var="grafana_admin_password=YourActualGrafanaPassword123!"
    ```
    Замініть `your-gcp-project-id` на ваш реальний ID проекту (за замовченням "focused-ion-452816-h5") та `YourActualGrafanaPassword123!` на ваш обраний пароль для Grafana (стандартний "YourSecurePassword123!" не рекомендований для використання). Якщо значення у `variables.tf` вас влаштовують (після зміни паролю Grafana там), ви можете просто виконати `terraform plan` та `terraform apply` без аргументів `-var`.

9.  **Тестування CI/CD Пайплайну (Cloud Build Trigger):**
    *   Terraform створив тригер `tf-github-update`. Цей тригер автоматично спрацьовуватиме при push в гілку `main` у файли, що знаходяться в `gcp-terraform-project/source_code_for_pipeline/**`.
    *   **Перший запуск:**
        1.  Внесіть невеликі зміни у файли всередині директорії `gcp-terraform-project/source_code_for_pipeline/app/` (наприклад, в `index.html`).
        2.  Закомітьте та запуште зміни у гілку `main` вашого GitHub репозиторію.
        3.  Або запустіть тригер вручну в консолі Cloud Build:
            *   Перейдіть до Google Cloud Console -> Cloud Build -> Triggers.
            *   Знайдіть тригер `tf-github-update`.
            *   Натисніть "Run trigger".

10. **Перевірка Результатів та Доступ до Сервісів:**
    Після успішного виконання `terraform apply`, Terraform відобразить значення
    Terraform надасть інформацію для доступу до Grafana через виведення
    *   **Доступ до прикладу додатку (`my-simple-gke-app`):**
        Після того, як CI/CD пайплайн успішно виконається (після вашого першого push у `source_code_for_pipeline` або ручного запуску тригера), додаток буде розгорнуто.
        1.  Переконайтесь, що `kubectl` налаштований
        2.  Виконайте команду для отримання інформації про сервіс:
            ```bash
            kubectl get service my-simple-app-service --namespace default
            ```
        3.  Знайдіть `EXTERNAL-IP` для сервісу `my-simple-app` (тип `LoadBalancer`).
        4.  Відкрийте `http://<EXTERNAL-IP_my-simple-app>` у вашому браузері.

## Очищення Ресурсів

Щоб видалити всі ресурси, створені Terraform (використовуйте ті ж значення змінних, що й при `apply`, якщо вони відрізняються від стандартних):
```bash
cd environments/dev/
terraform destroy -var="project_id=your-gcp-project-id" -var="grafana_admin_password=YourActualGrafanaPassword123!"
```
Примітки
Переконайтеся, що сервісний акаунт, ключ якого (kubernetes-root.json) використовується, має достатньо дозволів для виконання всіх операцій.
disable_on_destroy = false для ресурсів google_project_service означає, що API не будуть вимкнені автоматично при видаленні цих ресурсів Terraform, якщо вони використовуються іншими ресурсами або були ввімкнені поза Terraform.
