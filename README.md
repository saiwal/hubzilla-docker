# Hubzilla-docker

## Features:

- Use Docker Compose to set up a fully functional [Hubzilla](https://hubzilla.org/page/info/discover) instance with just a few commands.
- Multi-arch prebuilt images available for amd64, arm64, arm/v7.
- Continuous Updates: The Docker image is built to allow for easy updates whenever new changes are made to the Hubzilla core or its dependencies.
- SMTP Integration: Built-in support for sending emails using [ssmtp](https://wiki.archlinux.org/title/SSMTP), making it easy to configure email notifications for your Hubzilla instance.

## Getting started

To get started with the project, simply follow these steps below.

### Deploying with prebuilt image

- Clone the Repository:

```
git clone https://github.com/saiwal/hubzilla-docker.git
cd hubzilla-docker
```

- Configure Your Environment: Update the `.env` file with your SMTP and database details.
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

## Advanced hub configuration

To edit `.htconfig.php` for configuring advanced hubzilla features connect to container using:

```
docker exec -it <hubzilla_container_name> bash
```

and use `nano` or `vim` to edit `.htconfig.php`

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
- [ ] Option to add custom addon/theme repos.
- [ ] Explore other database systems (Postgres, etc.)
- [ ] Add option to enable apps, account quotas, and other configuration options.

## Contributions and Feedback:

I welcome any contributions, suggestions, or feedback you might have! If you find any issues or have ideas for new features, please don’t hesitate to reach out or open an issue on the GitHub repository.
