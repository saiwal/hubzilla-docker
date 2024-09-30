#!/bin/bash


# Define the repository URL and the working directory
REPO_URL="https://framagit.org/hubzilla/core.git"
WORK_DIR="/var/www/html"

# Substitute the environment variables into ssmtp config and revaliases
envsubst < /etc/ssmtp/ssmtp.conf.template > /etc/ssmtp/ssmtp.conf
envsubst < /etc/ssmtp/revaliases.template > /etc/ssmtp/revaliases

# Set permissions to ensure that the config files are accessible
chown root:mail /etc/ssmtp/ssmtp.conf
chmod 640 /etc/ssmtp/ssmtp.conf

chown root:mail /etc/ssmtp/revaliases
chmod 640 /etc/ssmtp/revaliases

# Check if the directory is empty (i.e., first container start)
if [ ! -d "$WORK_DIR/.git" ]; then
    echo "Cloning Hubzilla repository..."
    su www-data -s /bin/bash -c "git clone $REPO_URL $WORK_DIR"
    su www-data -s /bin/bash -c "util/add_addon_repo https://framagit.org/hubzilla/addons.git addons-official" 
else
    echo "Updating Hubzilla repository..."
    su www-data -s /bin/bash -c "git pull origin master"
fi

# Pull latest changes
su www-data -s /bin/bash -c "$WORK_DIR/util/udall"

# Start cron
service cron start

# Start Apache in the foreground
apache2-foreground

