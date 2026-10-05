#!/usr/bin/env bash
# deploy.sh — развёртывание стека notes_devops на сервере
#
# Использование:
#   ./deploy.sh [--pull] [--no-cache] [--skip-migrations] [--skip-smoke] [--prune]
#
#   --pull             git pull перед сборкой
#   --no-cache         пересобрать образы без кэша
#   --skip-migrations  не применять миграции
#   --skip-smoke       не выполнять проверки после запуска
#   --prune            удалить dangling-образы после успешного деплоя (тома не трогаются)
#
# Настройки ниже можно переопределить переменными окружения, например:
#   MIGRATE_CMD="" ./deploy.sh
#   RELEASE_VERSION=1.2.0 ./deploy.sh --no-cache

set -Eeuo pipefail

# ---------- Настройки ----------
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"   # явно: override на сервере не подхватится
BACKEND_SERVICE="${BACKEND_SERVICE:-notes-backend}"
DB_SERVICE="${DB_SERVICE:-notes-db}"                       # имя СЕРВИСА БД в compose (не container_name)
NGINX_IMAGE="${NGINX_IMAGE:-notes-nginx}"
BUILD_NGINX_WITH_SECRETS="${BUILD_NGINX_WITH_SECRETS:-1}"  # 0, если сертификаты монтируются при запуске
MIGRATE_CMD="${MIGRATE_CMD:-alembic upgrade head}"
HTTPS_PORT="${HTTPS_PORT:-8443}"
HEALTH_PATH="${HEALTH_PATH:-/api/health}"
NOTES_PATH="${NOTES_PATH:-/api/notes/}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180}"
RELEASE_VERSION="${RELEASE_VERSION:-1.0.0}"

BASE_URL="https://localhost:${HTTPS_PORT}"

DO_PULL=0
NO_CACHE=""
SKIP_MIGRATIONS=0
SKIP_SMOKE=0
DO_PRUNE=0

for arg in "$@"; do
  case "$arg" in
    --pull)            DO_PULL=1 ;;
    --no-cache)        NO_CACHE="--no-cache" ;;
    --skip-migrations) SKIP_MIGRATIONS=1 ;;
    --skip-smoke)      SKIP_SMOKE=1 ;;
    --prune)           DO_PRUNE=1 ;;
    -h|--help)         sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Неизвестный аргумент: $arg" >&2; exit 2 ;;
  esac
done

# ---------- Вспомогательные функции ----------
log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    ✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m    ✘ %s\033[0m\n' "$*" >&2; exit 1; }

compose() { docker compose -f "$COMPOSE_FILE" "$@"; }

on_error() {
  local line=$1
  trap - ERR
  printf '\n\033[1;31mДеплой прерван (строка %s). Состояние стека:\033[0m\n' "$line" >&2
  compose ps -a >&2 || true
  printf '\n\033[1;31mПоследние логи backend:\033[0m\n' >&2
  compose logs --tail 30 "$BACKEND_SERVICE" >&2 || true
  exit 1
}
trap 'on_error $LINENO' ERR

retry() {
  # retry <попыток> <пауза_сек> <команда...>
  local attempts=$1 delay=$2 i
  shift 2
  for ((i = 1; i <= attempts; i++)); do
    "$@" && return 0
    sleep "$delay"
  done
  return 1
}

check_health() {
  local body
  body=$(curl -fsSk --max-time 5 "${BASE_URL}${HEALTH_PATH}") || return 1
  grep -q '"db":[[:space:]]*true' <<<"$body"
}

http_code() {
  curl -sk -o /dev/null -w '%{http_code}' --max-time 5 "$1"
}

# Работаем из каталога со скриптом (корень репозитория)
cd "$(dirname "$(readlink -f "$0")")"

# ---------- 0. Предварительные проверки ----------
log "Проверка окружения"
for cmd in docker openssl curl git; do
  command -v "$cmd" >/dev/null || die "Не найдено: $cmd"
done
docker compose version >/dev/null 2>&1 || die "Не найден docker compose (плагин v2)"
[[ -f "$COMPOSE_FILE" ]] || die "Нет файла $COMPOSE_FILE"
ok "$(docker compose version)"

# Скрипты, пришедшие с Windows, могут иметь CRLF-окончания
if [[ -f nginx/generate-cert.sh ]] && grep -q $'\r' nginx/generate-cert.sh; then
  sed -i 's/\r$//' nginx/generate-cert.sh
  warn "Исправлены CRLF-окончания в nginx/generate-cert.sh"
fi

# ---------- 1. Обновление кода ----------
if (( DO_PULL )); then
  log "git pull"
  git pull --ff-only
  ok "Код обновлён: $(git rev-parse --short HEAD)"
fi

# ---------- 2. Файл .env ----------
log "Переменные окружения (.env)"
if [[ ! -f .env ]]; then
  [[ -f .env.example ]] || die "Нет ни .env, ни .env.example"
  cp .env.example .env
  # hex-пароль: без спецсимволов, безопасен внутри DATABASE_URL
  sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -hex 16)|" .env
  chmod 600 .env
  ok ".env создан из .env.example, сгенерирован DB_PASSWORD"
else
  ok ".env уже существует, не трогаем"
fi

# ---------- 3. Версия релиза для фронтенда (BuildKit secret) ----------
log "Версия релиза"
if [[ -z "$RELEASE_VERSION" ]]; then
  RELEASE_VERSION=$(git describe --tags --always 2>/dev/null || date +%Y.%m.%d)
fi
printf '%s' "$RELEASE_VERSION" > frontend/release_version.txt
ok "release_version = $RELEASE_VERSION"

# ---------- 4. Самоподписанный сертификат ----------
log "TLS-сертификат"
if [[ -f nginx/ssl/server.key && -f nginx/ssl/server.crt ]]; then
  ok "Сертификат уже есть, срок: $(openssl x509 -in nginx/ssl/server.crt -noout -enddate | cut -d= -f2)"
else
  (cd nginx && bash generate-cert.sh)
  ok "Сертификат сгенерирован"
fi

# ---------- 5. Образ nginx с BuildKit secrets ----------
if (( BUILD_NGINX_WITH_SECRETS )); then
  log "Сборка $NGINX_IMAGE (BuildKit secrets)"
  (
    cd nginx
    DOCKER_BUILDKIT=1 docker build $NO_CACHE \
      --secret id=cert_key,src=ssl/server.key \
      --secret id=cert_crt,src=ssl/server.crt \
      -t "$NGINX_IMAGE" .
  )
  ok "Образ $NGINX_IMAGE собран"
fi

# ---------- 6. Проверка конфигурации compose ----------
log "docker compose config"
compose config --quiet
ok "Конфигурация валидна"

# ---------- 7. Сборка остальных образов ----------
log "Сборка образов compose"
compose build $NO_CACHE
ok "Образы собраны"

# ---------- 8. База данных ----------
log "Запуск БД и ожидание healthy"
compose up -d --wait --wait-timeout "$WAIT_TIMEOUT" "$DB_SERVICE"
ok "БД готова"

# ---------- 9. Миграции ----------
if (( SKIP_MIGRATIONS )) || [[ -z "$MIGRATE_CMD" ]]; then
  warn "Миграции пропущены"
else
  log "Миграции: $MIGRATE_CMD"
  # одноразовый контейнер из образа backend: та же сеть и переменные окружения
  compose run --rm --no-deps "$BACKEND_SERVICE" sh -c "$MIGRATE_CMD"
  ok "Миграции применены"
fi

# ---------- 10. Весь стек ----------
log "Запуск стека и ожидание healthy"
compose up -d --remove-orphans --wait --wait-timeout "$WAIT_TIMEOUT"
compose ps
ok "Стек запущен"

# ---------- 11. Smoke-тесты через nginx ----------
if (( SKIP_SMOKE )); then
  warn "Проверки пропущены"
else
  log "Smoke-тесты (${BASE_URL})"

  retry 10 3 check_health || die "${HEALTH_PATH}: нет ответа или db != true"
  ok "${HEALTH_PATH} -> db: true"

  code=$(http_code "${BASE_URL}${NOTES_PATH}")
  [[ "$code" == "200" ]] || die "${NOTES_PATH}: HTTP $code"
  ok "${NOTES_PATH} -> 200"

  code=$(http_code "${BASE_URL}/")
  [[ "$code" == "200" ]] || die "SPA /: HTTP $code"
  ok "SPA / -> 200"
fi

# ---------- 12. Уборка ----------
if (( DO_PRUNE )); then
  log "Удаление dangling-образов (тома не затрагиваются)"
  docker image prune -f
fi

log "Готово: ${BASE_URL} (версия ${RELEASE_VERSION})"
