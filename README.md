# coder-config

`coder-config` is a Terraform config that provisions a developer machine using [Hanzo](http://hanzo.sh/)
and [Coder](https://coder.com/).

## Requirements

- Docker
- [Coder CLI](https://github.com/coder/coder#install)
- A running Coder deployment (check [Usage section](#usage))

## Usage

To configure Coder server, copy and update the `.env` file:
```bash
# Use production .env file
cp .env.production .env
```

Then, fill the `.env` file with values related to your setup (example):
```
CODER_VERSION=v2.4.0
CODER_ACCESS_URL=https://dev.example.com
CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS=true
CODER_OAUTH2_GITHUB_ALLOWED_ORGS="devenv-team"
CODER_OAUTH2_GITHUB_CLIENT_ID="00000000000000000000"
CODER_OAUTH2_GITHUB_CLIENT_SECRET="0000000000000000000000000000000000000000"
CODER_DISABLE_PASSWORD_AUTH=true
POSTGRES_VERSION=16
POSTGRES_USER=dev
POSTGRES_PASSWORD=dev
POSTGRES_DB=devenv
```

Now you can start the Coder server as follows:
```bash
docker compose up -d
```
