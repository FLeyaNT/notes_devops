#!/bin/sh
set -eu
cd /opt/devops-stack
ACTIVE=$(cat active_color 2>/dev/null || echo none)
if [ "$ACTIVE" = "blue" ]; then NEW=green; PORT=9445; else NEW=blue; PORT=9443; fi
echo "active: $ACTIVE -> deploying $NEW on :$PORT (tag $IMAGE_TAG)"
export HTTPS_PORT=$PORT IMAGE_TAG
docker compose -p "notes-$NEW" -f docker-compose.bg.yml pull
docker compose -p "notes-$NEW" -f docker-compose.bg.yml up -d --wait --wait-timeout 180
curl -fsSk "https://127.0.0.1:$PORT/api/health"
sudo /usr/local/sbin/notes-switch "$NEW"
echo "switched to $NEW. rollback: sudo /usr/local/sbin/notes-switch $ACTIVE"