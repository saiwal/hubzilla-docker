# Hubzilla-docker

> **Upgrading from an older checkout?** `.env` and `docker-compose.yml` are now gitignored; the repo ships `.env.example` and `docker-compose.yml.example` instead. A plain `git pull` will fail (or delete your `docker-compose.yml`), so keep your copies aside while pulling:
>
> ```
> cp .env .env.bak; cp docker-compose.yml docker-compose.yml.bak
> git checkout -- .env docker-compose.yml
> git pull
> mv .env.bak .env; mv docker-compose.yml.bak docker-compose.yml
> ```
>
> Existing `.env` files keep working: the new `HZ_REPO`, `ADDON_REPOS` and `THEME_REPOS` settings default to the previous built-in repos. See `.env.example` to customise them.

## Features:

- Use Docker Compose to set up a fully functional [Hubzilla](https://hubzilla.org/page/info/discover) instance with just a few commands.
- Multi-arch prebuilt images available for amd64, arm64, arm/v7.
- Continuous Updates: The Docker image is built to allow for easy updates whenever new changes are made to the Hubzilla core or its dependencies.
- SMTP Integration: Built-in support for sending emails using [ssmtp](https://wiki.archlinux.org/title/SSMTP), making it easy to configure email notifications for your Hubzilla instance.
- Ships with the [Utsukta hub themes](https://github.com/saiwal/Utsukta-hub-themes) repo (including `solidified`, the SPA theme), auto updates on first start and subsequent container restarts.

## Getting started

To get started with the project, simply follow these steps below.

### Deploying with prebuilt image

- Clone the Repository:

```
git clone https://github.com/saiwal/hubzilla-docker.git
cd hubzilla-docker
```

- Configure Your Environment: Copy the example files, then update `.env` with your SMTP and database details (both copies are gitignored):

```
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
```

- Run the Container:

```
docker compose up -d
```

### building image

Replace the following

```
image: ghcr.io/saiwal/hubzilla-docker:latest
```

with:

```
    build:
      context: .
      dockerfile: Dockerfile
      args:  # Pass build arguments here
        SSMTP_ROOT: ${SSMTP_ROOT}
        SSMTP_MAILHUB: ${SSMTP_MAILHUB}
        SSMTP_AUTHUSER: ${SSMTP_AUTHUSER}
        SSMTP_AUTHPASS: ${SSMTP_AUTHPASS}
        SSMTP_USESTARTTLS: ${SSMTP_USESTARTTLS}
        SSMTP_FROMLINEOVERRIDE: ${SSMTP_FROMLINEOVERRIDE}
        REVALIASES_ROOT: ${REVALIASES_ROOT}
        REVALIASES_WWWDATA: ${REVALIASES_WWWDATA}
      image: hubzilla

```

- Build and Run the Container:

```
docker compose up -d
```

or the following if you need a clean rebuild:

```
docker build --no-cache -t hubzilla -f Dockerfile .
docker compose up -d
```

Access Your Hubzilla Instance: Navigate to https://domain.tld (or the appropriate URL) to view your Hubzilla instance.

## Updating

Simply restart the container and it will pull the latest version of hubzilla from its repository and update addon/theme repositories.

```
docker compose restart
```

## Pinning/switching Hubzilla version

By default (`HUBZILLA_VERSION=master` in `.env`) the container tracks the `master` branch and updates on every restart. Set `HUBZILLA_VERSION` to a branch (e.g. `dev`) to track a different branch instead, or to a release tag (e.g. `9.4.4`) to pin to that exact version — pinned checkouts stop auto-updating on restart. Change the value in `.env` and restart:

```
docker compose restart
```

Prebuilt images are also tagged with the Hubzilla version current at build time (e.g. `ghcr.io/saiwal/hubzilla-docker:9.4.4`) in addition to `:latest`, for traceability — note this only reflects what version was current when the image was built, it does not pin the container's Hubzilla checkout (use `HUBZILLA_VERSION` for that).

## Custom core/addon/theme repos

Set these in `.env` and restart:

- `HZ_REPO` — Hubzilla core repo (default `https://framagit.org/hubzilla/core.git`).
- `ADDON_REPOS` / `THEME_REPOS` — comma-separated `<url> <name> [tag]` entries, e.g.
  `ADDON_REPOS=https://framagit.org/hubzilla/addons.git addons-official 9.4.4, https://example.com/more.git more-addons`

New repos are added on the next restart and unpinned repos are updated on every restart. The optional tag pins a repo to that release tag; drop it to return the repo to its default branch. Removing an entry does not delete an already-added repo.

## Advanced hub configuration

To edit `.htconfig.php` for configuring advanced hubzilla features connect to container using:

```
docker exec -it <hubzilla_container_name> bash
```

and use `nano` or `vim` to edit `.htconfig.php`

You may refer to the [official mariadb instructions](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/installing-mariadb/binary-packages/automated-mariadb-deployment-and-administration/docker-and-mariadb/installing-and-using-mariadb-via-docker) for accessing, configuring and optimizing your database.

## Why Docker?

Using Docker for Hubzilla provides several advantages:

- Isolation: Each instance runs in its own container, preventing conflicts with other applications.
- Portability: Easily move your setup between different environments (development, staging, production) with minimal effort.
- Consistency: The same environment can be replicated on any machine that supports Docker, ensuring that "it works on my machine" is no longer a valid excuse.

## Tips

- Using `http://` instead of `https://` in siteurl on initial setup will break federation and discovery. Make sure to use SSL and https.
- SMTP environment variables are necessary for admin registration. Make sure they are specified in the `.env` files correctly. Use app passwords if necessary for services with TFA(gmail, etc.).
- Upload size limit is controlled by custom-php.ini, currently set to 20MB. Change if needed to appropriate value.

## Adjusting for use behind a reverse proxy

If you are exposing the containers to the public behind a reverse proxy, some additional steps are needed for logging in the IP addresses of visitors:

1. Access the console of your app container by `docker exec -it <container name> bash`.
2. Enable the `mod_remoteip` module in apache `a2enmod remoteip`.
3. Update the apache configuration, add the following to `/etc/apache2/sites-enabled/default000.conf` and replace the IP with the IP of the reverse proxy.

```
    <IfModule mod_remoteip.c>
        RemoteIPHeader X-Forwarded-For
        # Specify the trusted proxy IPs (replace with your Reverse Proxy IP or network)
        RemoteIPTrustedProxy <REVERSE_PROXY_IP>
    </IfModule>
```

4. Restart apache with `systemctl restart apache2`.
5. Check the logs with `docker compose logs --follow --tail=50`.

## TODO

- [ ] Optimize image size.
- [x] Option to add custom addon/theme repos.
- [ ] Explore other database systems (Postgres, etc.)
- [ ] Add option to enable apps, account quotas, and other configuration options.

## Contributions and Feedback:

I welcome any contributions, suggestions, or feedback you might have! If you find any issues or have ideas for new features, please don’t hesitate to reach out or open an issue on the GitHub repository.
