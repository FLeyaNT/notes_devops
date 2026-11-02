#!/bin/sh
set -eu
cd /opt/devops-stack
ACTIVE=$(cat active_color 2>/dev/null || echo none)
if [ "$ACTIVE" = "blue" ]; then NEW=green; PORT=9445; else NEW=blue; PORT=9443; fi
echo "active: $ACTIVE -> deploying $NEW on :$PORT (tag $IMAGE_TAG)"
export HTTPS_PORT=$PORT IMAGE_TAG
DC="docker compose -p notes-$NEW -f docker-compose.bg.yml"
$DC pull
# у каждого цвета своя БД: сначала поднимаем её и применяем миграции
$DC up -d --wait --wait-timeout 120 notes-db
$DC run --rm -T --no-deps notes-backend alembic upgrade head
$DC up -d --wait --wait-timeout 180
# переключаем трафик, только если новый цвет реально отвечает (health + чтение из БД)
for path in /api/health /api/notes/; do
  ok=0
  for i in 1 2 3 4 5; do
    curl -fsSk -o /dev/null "https://127.0.0.1:$PORT$path" && { ok=1; break; } || sleep 3
  done
  [ "$ok" = 1 ] || { echo "check $path on $NEW failed, traffic stays on $ACTIVE"; exit 1; }
  echo "check $path on $NEW: ok"
done
sudo /usr/local/sbin/notes-switch "$NEW"
echo "switched to $NEW. rollback: sudo /usr/local/sbin/notes-switch $ACTIVE"
