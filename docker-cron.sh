#!/usr/bin/env bash

set -euxo pipefail

CLOUDFLARE_EMAIL="you@example.com" \
    CLOUDFLARE_API_KEY="yourprivatecloudflareapikey" \
    lego --email "you@example.com" --dns cloudflare --domains "example.org" run

exec crond -n
