#!/bin/bash
set -e
cd "$(dirname "$0")"

echo 'build image and (re)create container'
docker compose up -d --build
docker compose ps
