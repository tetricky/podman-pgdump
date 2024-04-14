#!/bin/bash

# Database credentials
PG_CONTAINER="postgresql_container_name"
DB_USER="postgres_superuser"
DB_PASSWORD="postgres_superuser_password"

# Backup directory
BACKUP_DIR="/var/lib/postgresql_dumps"

# Backup rotation (number of backups to keep)
BACKUP_ROTATE=3

# Notifications 
NTFY_SERVER="https://ntfy.sh"
NTFY_TOPIC="mytopic"
NTFY_AUTH="ntfy_username:ntfy_password"

# Function to send notification
send_notification() {
  tag="$1"
  body="$2"
  curl --silent -u $NTFY_AUTH -H "Priority: high" -H "Tags: $tag" -H "X-Title: $NTFY_TOPIC" -d "$body" $NTFY_SERVER/$NTFY_TOPIC > /dev/null
}

# Create timestamped backup filename
timestamp=$(date '+%Y-%m-%d_%H:%M:%S-(%Z)')
backup_file="$BACKUP_DIR/postgres_$timestamp.sql.gz"

# Dump all databases and compress the backup
send_notification "computer" "pgdump script STARTED"

podman exec -i $PG_CONTAINER /bin/bash -c "PGPASSWORD=$DB_PASSWORD pg_dumpall --username $DB_USER" | gzip > "$backup_file"

if [[ $? -eq 0 ]]; then
  # Backup successful
  dump_size=$(ls -lah $backup_file | awk '{ print $5}')
  send_notification "+1" "pgdump size $dump_size"

  # Rotate backups (delete oldest if exceeding retention limit)
  count=$(ls -tr "$BACKUP_DIR" | grep '^postgres_' | wc -l)
  if [[ $count -gt $BACKUP_ROTATE ]]; then
    rm -f "$BACKUP_DIR"/$(ls -tr "$BACKUP_DIR" | grep '^postgres_' | head -n -$((count - BACKUP_ROTATE)))
  fi
else
  # Backup failed
  send_notification "skull" "pgdump FAILED."
fi

