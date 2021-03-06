#!/bin/bash
# DB credentials
USER="gitea"
PASS="secret"
DATABASE="gitea"
# restore of the gitea backup if created with its given ID
# we will use the command line method given in Gitea's documentation
# https://docs.gitea.io/en-us/backup-and-restore/


sudo rm -rf /etc/gitea/app.ini /var/lib/gitea/data/* /var/lib/gitea/log/* /var/lib/gitea/gitea-repositories/*

sudo -H -u git bash -c '

# Backup location
REMOTE_SERVER="etudiant@192.168.1.2"
# ID is the value of the server backup to be restored
ID=""
echo "Please provide the Backup ID:"
read ID
BACKUP="/Data/etudiant/Backup-gitea/$ID.zip"
REMOTE_BACKUP="$REMOTE_SERVER:$BACKUP"
SSH_CRED="/home/git/.ssh/giteakey"

if ssh -q -o "StrictHostKeyChecking=no" -i $SSH_CRED $REMOTE_SERVER test -e $BACKUP; then
    # Collects the backup from the remote server
    echo "=> [1]: Collecting backup from remote server..."
    rm -rf /home/git/backup-recovery
    mkdir /home/git/backup-recovery && cd /home/git/backup-recovery
    scp -q -i $SSH_CRED $REMOTE_BACKUP /home/git/backup-recovery/ 
    echo "END - Collecting backup from remote server..."
    unzip $ID.zip ;
    echo "=> [2]: Restoring backup..."
    mkdir /var/lib/gitea/data/gitea-repositories
    mv -f app.ini /etc/gitea/app.ini
    mv -f data/* /var/lib/gitea/data/
    mv -f log/* /var/lib/gitea/log/
    mv -f repos/* /var/lib/gitea/data/gitea-repositories/
    
    echo "END - Backup restored"
fi
'
sudo mysql --default-character-set=utf8mb4 -uroot $DATABASE < /vagrant/data/db_reset.sql
sudo mysql --default-character-set=utf8mb4 -u$USER -p$PASS $DATABASE < /home/git/backup-recovery/gitea-db.sql
sudo chown -R git:git /etc/gitea/app.ini /var/lib/gitea
service gitea restart