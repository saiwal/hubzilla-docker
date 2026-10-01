#!/bin/bash


# Repo URLs and working directory (override via .env)
HZ_REPO="${HZ_REPO:-https://framagit.org/hubzilla/core.git}"
WORK_DIR="/var/www/html"

# Comma-separated list of "<url> <name>" pairs
ADDON_REPOS="${ADDON_REPOS:-https://framagit.org/hubzilla/addons.git addons-official}"
THEME_REPOS="${THEME_REPOS:-https://github.com/saiwal/Utsukta-hub-themes.git utsukta-themes}"

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
    su www-data -s /bin/bash -c "git clone $HZ_REPO $WORK_DIR"
    su www-data -s /bin/bash -c "git checkout $HUBZILLA_VERSION"
else
    echo "Checking out Hubzilla $HUBZILLA_VERSION..."
    su www-data -s /bin/bash -c "git remote set-url origin $HZ_REPO"
    # git pull no-ops (fails harmlessly) when $HUBZILLA_VERSION is a tag,
    # since checkout leaves us on a detached HEAD with no tracking branch.
    su www-data -s /bin/bash -c "git fetch --all --tags && git checkout $HUBZILLA_VERSION && git pull origin $HUBZILLA_VERSION"
fi

# Add any addon/theme repos not yet present and apply tag pins; udall below
# updates unpinned repos (its `git pull` fails harmlessly on pinned, detached ones).
add_repos() { # $1 = addon|theme, $2 = comma-separated "<url> <name> [tag]" list
    IFS=',' read -ra entries <<< "$2"
    for entry in "${entries[@]}"; do
        read -r url name tag <<< "$entry"
        [ -z "$url" ] && continue
        dir="extend/$1/$name"
        if [ ! -d "$WORK_DIR/$dir" ]; then
            echo "Adding $1 repository $name ($url)..."
            su www-data -s /bin/bash -c "util/add_$1_repo $url $name"
        fi
        if [ -n "$tag" ]; then
            echo "Pinning $1 repository $name to $tag..."
            su www-data -s /bin/bash -c "git -C $dir fetch -q --tags && git -C $dir checkout -q $tag"
        else
            # Unpinned: if left detached by an earlier pin, return to the default branch.
            su www-data -s /bin/bash -c "git -C $dir symbolic-ref -q HEAD >/dev/null || git -C $dir checkout -q \$(git -C $dir symbolic-ref --short refs/remotes/origin/HEAD | sed 's#^origin/##')"
        fi
    done
}
add_repos addon "$ADDON_REPOS"
add_repos theme "$THEME_REPOS"

# Pull latest changes for core/addons/themes and run db updates. When
# $HUBZILLA_VERSION is a tag, core is in detached HEAD state so udall's
# internal `git pull` fails harmlessly and leaves the pinned checkout intact.
su www-data -s /bin/bash -c "$WORK_DIR/util/udall"

# Start cron
service cron start

# Start Apache in the foreground
apache2-foreground

