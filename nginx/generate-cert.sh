#!/bin/sh

export MSYS_NO_PATHCONV=1

mkdir -p ssl
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout ssl/server.key \
    -out ssl/server.crt \
    -subj "/CN=devops-stack.local" \
    -addext "subjectAltName=DNS:devops-stack.local,DNS:localhost,IP:127.0.0.1"
chmod 600 ssl/server.key
