#!/bin/bash

echo "=== [ Certbot manual renewal start: $(date) ] ==="

docker compose -f /root/chirpstack-docker/docker-compose.certbot.yml exec certbot certbot renew --webroot -w /var/www/certbot --deploy-hook "docker exec nginx nginx -s reload"

RET=$?

if [ $RET -eq 0 ]; then
  echo "=== [ Renewal completed successfully at $(date) ] ==="
else
  echo "!!! [ Renewal failed at $(date) with exit code $RET ] !!!"
fi
