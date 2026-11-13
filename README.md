# Remote Media Storage FASP 

This Fediverse Auxiliary Service Provider (FASP) implements an early
draft of the `rms` capability. It allows fediverse servers to request
the download and storage of remote images. These images can then be
requested in different formats and dimensions.

Once finished, this will allow fediverse servers to pool storage for
remote images, which make up a sizeable portion of storage cost for
hosting fediverse servers.

This project is a proof-of-concept of an early specification draft and
should not be used in production environments.

## Architecture

![Simple architecture diagram showing rms_fasp, object storage, imgproxy
and reverse proxy](/docs/rms_fasp_architecture.svg)

When asked to store media files, rms_fasp will download image files from
fediverse servers and store them in an S3-compatible object storage.

When a file is requested, it will generate a URL to an imgproxy service.
imgproxy then downloads the correct file from object storage and, if
necessary, performs conversions on-the-fly.

A reverse proxy or CDN in front of these services can be configured to
make this appear like a single service to end users and add a caching
layer.

## Installation

### Manual

Prerequisites:

* Ruby (we recommend using a version manager such as asdf or rbenv,
  which will pick up the correct version from `.ruby-version`)
* PostgreSQL (tested with version 16, but others should work just as
  well)

Note that the following is a high-level description of the installation
steps. Some details may vary depending on the operating system or distro
used.

#### Step 1: Clone the Repo:

```sh
git clone https://github.com/mastodon/rms_fasp.git
cd rms_fasp
```

#### Step 2: Install Ruby Dependencies

```sh
bundle install
```

(Note that installation of Ruby gems may fail if they depend on
some native library and development headers being present. One such
example could be the PostgreSQL client library. In this case you need to
install the missing libraries using your operating system's package
manager.)

#### Step 3: Create a Secret Key Base

Running

```sh
bin/rails secret
```

will print out a random secret suitable for use as Rails' "secret key
base", a value used as a basis for cryptographic operations that should
be unique to every installation of rms_fasp.

Place this value in the `SECRET_KEY_BASE` environment variable so it is
available in the following steps:

```sh
export SECRET_KEY_BASE=<long random key here>
```

Also make note of this value for later use. You should also consider
adding this to the shell startup scripts of the user running
rms_fasp or a `.env` file or similar, so you do not need to repeat
this step every time to run maintenance tasks.

#### Step 4: Create And Setup Databases

The database is configured in `config/database.yml`, under the
`production` key. The configuration in this repository expects three
distinct databases to be present: `rms_fasp_production`,
`rms_fasp_production_cache` and `rms_fasp_production_queue`.

A dedicated user, `rms_fasp`, needs to be present and have full read
and write access to these databases.

A password for said user can be given using the
`RMS_FASP_DATABASE_PASSWORD` environment variable.

If you are running PostgreSQL on a different host, you can use the
`DATABASE_URL` environment variable to provide a full (or rather
partial) `postgresql://` database url. You can leave out username and
database name as these get overwritten from `config/database.yml`
anyway.

Once your environment variables are set up, you can run

```sh
RAILS_ENV=production bin/rails db:setup
```

#### Step 5: Precompile Assets

Run the followin command to precompile CSS and JavaScript files:

```sh
RAILS_ENV=production bin/rails assets:precompile
```

#### Step 6: Start rms_fasp on System (Re)Start

You need to run two processes, the rms_fasp web application server
(puma) and the background job runner (Solid Queue).

We recommend using your operating system's process supervisor to do so
and make sure those processes are started on system startup.

You can find example files for systemd in the [`examples/`](examples/)
directory. Make sure to add / replace the environment variables in there
with the correct values for your system.

#### Step 7: Configure Object Storage and imgproxy

Sign-up for or install both a S3-compatible object storage service and
[imgproxy](https://imgproxy.net).

See [Configuration](#configuration) below on how to configure rms_fasp
to be able to use both services.

#### Step 8: Configure a Frontend Webserver / Reverse Proxy

We recommend you run the rms_fasp web application server behind a
full-fledged web server that acts as a reverse proxy, handles SSL/TLS
and serving of static files.

If desired it can also be configured to hide the presence of imgproxy
and make the whole system seem seamless to outside users.

To that end, when asked for an image file, rms_fasp will return a `302`
redirect with the `X-Accel-Redirect` header. The latter is supported by
at least nginx to realize "internal redirects". Other reverse proxies
can be configured to act on the presence of that header and/or the
combination of the `302` status code and the header to perform the
redirect internally.

Everything should work without this configuration, as long as imgproxy
is publicly accessible.

It is recommended to have the reverse proxy cache images and/or add an
extra CDN layer with caching.

### Docker

The provided [`Dockerfile`](Dockerfile) should be sufficient to run both
the ruby application server (started by default) and the background job
runner (in which you need to run `bin/jobs` instead of `bin/rails
server`).

This allows you to skip some of the steps of a manual installation, but
you still need most of them, so please read them carefully.

We also push ready-made container images to Github's registry.
Please see [packages](https://github.com/mastodon/rms_fasp/pkgs/container/rms_fasp).

<!-- ### Kubernetes -->

<!-- We provide an official Helm chart in our repository at -->
<!-- https://github.com/mastodon/helm-charts. -->

## Configuration

rms_fasp can be configured using environment variables. Here is a
(possibly incomplete) list:

### Basics

| Variable | Mandatory | Default | Description |
| -------- | --------- | ------- | ----------- |
| `SECRET_KEY_BASE` | Yes |  | Random key, unique per installation |
| `DOMAIN` | Yes | | The domain name under which the web application is accessible |
| `RMS_FASP_DATABASE_PASSWORD` | No | | Password of the `rms_fasp` user used to access the databases |
| `DATABASE_URL` | No |  | Optional PostgreSQL URL to set database host, port etc. |
| `WEB_CONCURRENCY` | No | `1` | Number of puma application server processes. Can be set to the number of CPUs to make use of all of them |
| `JOB_CONCURRENCY` | No | `1` | Number of Solid Queue processes. Can be set to the number of CPUs to make use of all of them |
| `FASP_NAME` | No | `rms_fasp` | The name of your instance, returned in provider info |
| `PRIVACY_POLICY_URL` | No | | A link to your privacy policy |
| `PRIVACY_POLICY_LANGUAGE` | No | | The two-letter code for the language your policy is written in |
| `CONTACT_EMAIL` | No | | A contact email for your instance |
| `FEDIVERSE_ACCOUNT` | No | | A contact fediverse account for your instance |
| `RMS_CSP_HOSTS` | No | `${DOMAIN}` | Comma separated list of hosts servers should allow in their CSP, default is fine in most cases, but you might want to add your imgproxy host if it is publicly accessible |


### Object Storage

| Variable | Mandatory | Default | Description |
| -------- | --------- | ------- | ----------- |
| `AWS_ENDPOINT_URL` | No | AWS S3 | Endpoint URL, needed when not using original S3 |
| `AWS_ACCESS_KEY_ID` | Yes |   | Access key id |
| `AWS_SECRET_ACCESS_KEY` | Yes |   | Secret key |
| `AWS_REGION` | No |   | S3 region to use |

### imgproxy

| Variable | Mandatory | Default | Description |
| -------- | --------- | ------- | ----------- |
| `IMGPROXY_ENDPOINT` | Yes |  | Base URL of your imgproxy service |
| `IMGPROXY_KEY` | Yes |   | Secret key for URL signing |
| `IMGPROXY_SALT` | Yes |   | Salt for URL signing |

<!-- ### OTEL -->

<!-- Further environment variables can be set for opentelemetry see -->
<!-- [the official documentation](https://opentelemetry.io/docs/languages/sdk-configuration/general/) -->

## Development

For local development, a Docker Compose file is provided that spins up
imgproxy and garage, a S3 compatible object storage service.

To use this, first create a `.env.development` file:

```sh
bin/rails generate dev:env
```

This will generate environment variables in a way that all services are
set up to be able to talk to each other.

After this you can spin up the containers with:

```sh
docker compose -f docker-compose-dev.yml up
```

## Contributing

See https://github.com/mastodon/.github/blob/main/CONTRIBUTING.md

## License

Copyright (c) 2026 Mastodon GmbH and contributors

Licensed under GNU Affero General Public License as stated in the [LICENSE](LICENSE):

```
Copyright (c) 2026 Mastodon GmbH & contributors

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see https://www.gnu.org/licenses/
```
