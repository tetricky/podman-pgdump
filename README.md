# podman-pgdump

A simple bash script to dump all postgresql databases in a running podman container and send ntfy notifications. pg_dumpall_ntfy.sh

## Usage

The script does not do comprehensive checking, but can be run manually or automated (eg CRON). I use this script to do database dumps on an independent schedule, and to place the backups in a directory that is subsequently backed up (I use [docker-borgmatic](https://github.com/borgmatic-collective/docker-borgmatic) in a podman pod). Setting a suitable retention (automation interval, plus `BACKUP_ROTATE` setting) allows for multiple database dumps to be retained per backup run.

## Important note

The dump command `podman exec -i $PG_CONTAINER /bin/bash -c "PGPASSWORD=$DB_PASSWORD pg_dumpall --username $DB_USER" | gzip > "$backup_file"` includes writing to a file, it will complete successfully as long as the file is written - Not necessarily because the dump has worked. The notification on complete therefore notifies of the current database dump filesize. I monitor these through the ntfy notifications, and periodically check the dump files.

This script was created as a quick and dirty workaround because [docker-borgmatic](https://github.com/borgmatic-collective/docker-borgmatic) does not currently support postgresql 16 as per issue [pg_dump does not support postgresql 16.](https://github.com/borgmatic-collective/docker-borgmatic/issues/313).
