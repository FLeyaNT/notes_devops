FROM nginx:1.27-alpine

# Свой конфиг заменяет дефолтный (одноимённый файл перезаписывается)
COPY conf.d/default.conf /etc/nginx/conf.d/default.conf

# Сертификат и ключ в образ не кладём: их монтирует compose в /etc/nginx/ssl
EXPOSE 8443

HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -qO- --no-check-certificate https://127.0.0.1:8443/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]