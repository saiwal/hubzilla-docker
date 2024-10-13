# Hubzilla-docker

## Features:

- Use Docker Compose to set up a fully functional [Hubzilla](https://hubzilla.org/page/info/discover) instance with just a few commands.
- Multi-arch prebuilt images available for amd64, arm64, arm/v7.
- Continuous Updates: The Docker image is built to allow for easy updates whenever new changes are made to the Hubzilla core or its dependencies.
- SMTP Integration: Built-in support for sending emails using [ssmtp](https://wiki.archlinux.org/title/SSMTP), making it easy to configure email notifications for your Hubzilla instance.

## Getting started

To get started with the project, simply follow these steps:

### Building the image from scratch

- Clone the Repository:

```
git clone https://github.com/saiwal/hubzilla-docker.git
cd hubzilla-docker
```

- Configure Your Environment: Update the `.env` file with your SMTP and database details.
- Build and Run the Container:

```
docker compose up --build -d
```

or the following if you need a clean rebuild:

```
docker build --no-cache -t hubzilla -f Dockerfile .
docker compose up -d
```

### Using prebuilt image

Replace the following

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

with:

```
image: ghcr.io/saiwal/hubzilla-docker:latest
```

and to deploy:

```
docker compose up -d
```

Access Your Hubzilla Instance: Navigate to http://localhost (or the appropriate URL) to view your Hubzilla instance.

## Updating

Simply restart the container and it will pull the latest version of hubzilla from its repository and update addon/theme repositories.

```
docker compose restart
```

## Advanced hub configuration

To edit `.htconfig.php` for configuring advanced hubzilla features connect to conatiner using:

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

## TODO

- [ ] Optimize image size.
- [ ] Option to add custom addon/theme repos.
- [ ] Explore other database systems (Postgres, etc.)
- [ ] Add option to enable apps, account quotas, and other configuration options.

## Contributions and Feedback:

I welcome any contributions, suggestions, or feedback you might have! If you find any issues or have ideas for new features, please don’t hesitate to reach out or open an issue on the GitHub repository.
