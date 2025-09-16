# Використовуємо базовий образ Alpine Linux з Nginx
FROM nginx:alpine

# Копіюємо простий HTML файл в директорію веб-сервера Nginx
COPY ./index.html /usr/share/nginx/html/index.html

# Відкриваємо порт 80
EXPOSE 80

# Команда для запуску Nginx при старті контейнера
CMD ["nginx", "-g", "daemon off;"]