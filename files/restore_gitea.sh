#!/bin/bash

# restore of the gitea backup if created with its given ID
# we will use the command line method given in Gitea's documentation
# https://docs.gitea.io/en-us/backup-and-restore/

# Backup location
REMOTE_SERVER="etudiant@192.168.0.42"
# ID is the value of the server backup to be restored
ID=""
BACKUP="/Data/etudiant/Backup-gitea/$ID.zip"
REMOTE_BACKUP="$REMOTE_SERVER:$BACKUP"
SSH_CRED="/home/git/.ssh/giteakey"
# DB credentials
USER="git"
PASS="secret"
DATABASE="gitea"

if ssh -i $SSH_CRED $REMOTE_SERVER test -e $BACKUP; then
    # Collects the backup from the remote server
    echo "=> [1]: Collecting backup from remote server..."
    su git
    mkdir /home/git/backup-recovery && cd /home/git/backup-recovery
    scp -o "StrictHostKeyChecking=no" -i $SSH_CRED $REMOTE_BACKUP /home/git/backup-recovery/
    echo "END - Collecting backup from remote server..."
    unzip $ID.zip
    echo "=> [2]: Restoring backup..."
    mv -f app.ini /etc/gitea/app.ini
    mv -f data/* /var/lib/gitea/data/
    mv -f log/* /var/lib/gitea/log/
    mv -f repos/* /var/lib/gitea/gitea-repositories

    su root
    chown -R git:git /etc/gitea/app.ini /var/lib/gitea 

    mysql --default-character-set=utf8mb4 -u$USER -p$PASS $DATABASE <gitea-db.sql

    service gitea restart
    echo "END - Backup restored"
fi
