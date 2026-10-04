# Использует alpine образ, чтобы уменьшить размер образа
FROM python:3.12-alpine
WORKDIR /app
# Установка зависимостей до исходников
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# В образ не попадают файлы обозначенные в .dockerignore
COPY . .
# Создаем пользователя чтобы производить сборку не от root
RUN adduser -D -H appuser
RUN chown appuser:appuser /app
USER appuser
EXPOSE 8000
# Exec form: бинарник — PID 1 и получает SIGTERM напрямую
CMD ["python", "-m", "app.main"]