#!/bin/bash

WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
LOG_FILE="/var/log/certbot-renew.log"
TMP_LOG="/tmp/certbot-run.log"
NOW=$(date +"%Y-%m-%d %H:%M:%S")

send_slack_notification() {
  local status="$1"
  local color="$2"
  local message="Let's Encrypt certificate renewal *$status* on \`$(hostname)\` at \`$NOW\`."

  curl -X POST -H 'Content-type: application/json' --silent --output /dev/null --data "{
    \"attachments\": [{
      \"fallback\": \"$message\",
      \"color\": \"$color\",
      \"text\": \"$message\"
    }]
  }" "$WEBHOOK_URL"
}

echo "=== [$NOW] Starting certificate renewal ===" >> "$LOG_FILE"

# Run certbot and capture full output in temp file
docker compose -f /root/chirpstack-docker/docker-compose.certbot.yml exec certbot certbot renew \
  --webroot -w /var/www/certbot > "$TMP_LOG" 2>&1

RET=$?
cat "$TMP_LOG" >> "$LOG_FILE"

if [ $RET -ne 0 ]; then
  echo "!!! [$NOW] Renewal failed with exit code $RET ===" >> "$LOG_FILE"
  send_slack_notification "FAILED (exit $RET)" "danger"
else
  if grep -q "Congratulations, all renewals succeeded:" "$TMP_LOG"; then
    echo "Reloading nginx container..." >> "$LOG_FILE"
    docker exec nginx nginx -s reload >> "$LOG_FILE" 2>&1

    echo "=== [$NOW] Renewal succeeded ===" >> "$LOG_FILE"
    send_slack_notification "SUCCEEDED – certificate renewed" "good"
  else
    echo "=== [$NOW] No renewal needed – no notification sent ===" >> "$LOG_FILE"
  fi
fi

rm -f "$TMP_LOG"
