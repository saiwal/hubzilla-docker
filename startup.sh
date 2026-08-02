#!/bin/bash


# Define the repository URL and the working directory
REPO_URL="https://framagit.org/hubzilla/core.git"
WORK_DIR="/var/www/html"

# HUBZILLA_VERSION: a branch (e.g. "master", "dev") to keep updating on every
# restart, or a release tag (e.g. "9.4.4") to pin to that version.
HUBZILLA_VERSION="${HUBZILLA_VERSION:-master}"

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
    su www-data -s /bin/bash -c "git checkout $HUBZILLA_VERSION"
    su www-data -s /bin/bash -c "util/add_addon_repo https://framagit.org/hubzilla/addons.git addons-official"
else
    echo "Checking out Hubzilla $HUBZILLA_VERSION..."
    # git pull no-ops (fails harmlessly) when $HUBZILLA_VERSION is a tag,
    # since checkout leaves us on a detached HEAD with no tracking branch.
    su www-data -s /bin/bash -c "git fetch --all --tags && git checkout $HUBZILLA_VERSION && git pull origin $HUBZILLA_VERSION"
fi

if [ ! -d "$WORK_DIR/extend/theme/utsukta-themes/.git" ]; then
    echo "Cloning theme repository..."
    su www-data -s /bin/bash -c "util/add_theme_repo https://github.com/saiwal/Utsukta-hub-themes.git utsukta-themes"
else
    echo "Updating theme repository..."
    su www-data -s /bin/bash -c "util/update_theme_repo utsukta-themes"
fi

# Pull latest changes for addons/themes and run db updates. When
# $HUBZILLA_VERSION is a tag, core is in detached HEAD state so udall's
# internal `git pull` fails harmlessly and leaves the pinned checkout intact.
su www-data -s /bin/bash -c "$WORK_DIR/util/udall"

# Start cron
service cron start

# Start Apache in the foreground
apache2-foreground

