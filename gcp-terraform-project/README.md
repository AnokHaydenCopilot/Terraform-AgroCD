# Проєкт Terraform Study

Цей проєкт призначений для управління інфраструктурою Google Cloud Platform (GCP) за допомогою Terraform. Він включає:

- Створення інфраструктури (віртуальні машини, мережі, брандмауери).
- Деплой Google Cloud Functions.
- Зберігання стану Terraform у Google Cloud Storage (GCS).

## Структура проєкту

```plaintext
Terraform-Study/
├── environments/
│   ├── dev/                # Середовище розробки
│   │   ├── main.tf         # Основна конфігурація Terraform
│   │   ├── variables.tf    # Змінні для середовища
│   │   ├── outputs.tf      # Вихідні дані Terraform
│   │   ├── backend.tf      # Налаштування бекенду для стану
│   │   └── README.md       # Документація для середовища
├── src/
│   ├── HTTP_Name_test/     # Код для Google Cloud Function
│   │   └── main.py         # Функція hello_http
├── .gitignore              # Ігнорування файлів для Git
└── README.md               # Основна документація
```

## Передумови

- Встановлений [Terraform](https://www.terraform.io/downloads.html).
- Обліковий запис Google Cloud Platform з відповідними правами доступу.
- Встановлений та налаштований [Google Cloud SDK](https://cloud.google.com/sdk/docs/install).

## Інструкції з налаштування

1. Клонуйте репозиторій:
   ```bash
   git clone <repository-url>
   cd gcp-terraform-project
   ```

2. Перейдіть до середовища розробки:
   ```bash
   cd environments/dev
   ```

3. Ініціалізуйте Terraform:
   ```bash
   terraform init
   ```

4. Перевірте конфігурацію:
   ```bash
   terraform validate
   ```

5. Створіть план змін:
   ```bash
   terraform plan
   ```

6. Застосуйте конфігурацію для створення ресурсів:
   ```bash
   terraform apply
   ```

7. Щоб знищити ресурси, коли вони більше не потрібні:
   ```bash
   terraform destroy
   ```

## Примітки

- Переконайтеся, що ви встановили необхідні змінні середовища для автентифікації з GCP.
- Змініть файл `variables.tf` у середовищі `dev`, щоб налаштувати розгортання за потреби.
- Використовуйте віддалене сховище стану для забезпечення узгодженості між членами команди.

## Посилання

- [Документація Terraform](https://www.terraform.io/docs)
- [Документація Google Cloud Platform](https://cloud.google.com/docs)