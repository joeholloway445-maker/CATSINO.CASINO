#!/usr/bin/env bash
# setup_certs.sh — Obtain Let's Encrypt TLS certs for all three domains.
# Run once on the VPS AFTER pointing DNS at this server and running deploy.sh
# (the nginx proxy must be up to handle the HTTP ACME challenge).
#
# Usage:  EMAIL=your@email.com bash scripts/setup_certs.sh
set -euo pipefail

source .env 2>/dev/null || true

EMAIL="${EMAIL:-}"
CATSINO_DOMAIN="${CATSINO_DOMAIN:-catsino.casino}"
HDV_DOMAIN="${HDV_DOMAIN:-periliminal.space}"
PLAY_DOMAIN="${PLAY_DOMAIN:-play.catsino.casino}"

if [ -z "$EMAIL" ]; then
  echo "Set EMAIL=your@email.com before running this script."
  exit 1
fi

BOLD="\033[1m"
GREEN="\033[32m"
RESET="\033[0m"

mkdir -p nginx/certs nginx/certbot-webroot

echo -e "${BOLD}Obtaining certs for: $CATSINO_DOMAIN $HDV_DOMAIN $PLAY_DOMAIN${RESET}"

docker run --rm \
  -v "$(pwd)/nginx/certs:/etc/letsencrypt" \
  -v "$(pwd)/nginx/certbot-webroot:/var/www/certbot" \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d "$CATSINO_DOMAIN" \
  -d "$HDV_DOMAIN" \
  -d "$PLAY_DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email

echo ""
echo -e "${GREEN}Certs obtained!${RESET}"
echo ""
echo "Next steps:"
echo "  1. Uncomment the HTTPS server blocks in nginx/proxy.conf"
echo "     (replace domain names with your actual domains)"
echo "  2. docker-compose restart proxy"
echo "  3. Visit https://$CATSINO_DOMAIN to verify"
echo ""
echo "Auto-renewal (add to crontab):"
echo "  0 0 * * * cd $(pwd) && docker run --rm -v \$(pwd)/nginx/certs:/etc/letsencrypt certbot/certbot renew && docker-compose restart proxy"
