#!/bin/sh
set -eu

if [ -n "${VERCEL_PROJECT_PRODUCTION_URL:-}" ]; then
  BASE_URL="https://${VERCEL_PROJECT_PRODUCTION_URL}/"
elif [ -n "${VERCEL_URL:-}" ]; then
  BASE_URL="https://${VERCEL_URL}/"
else
  BASE_URL="https://gaborl-hugo.vercel.app/"
fi

exec hugo --gc --minify --baseURL "$BASE_URL"
