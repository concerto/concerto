# Concerto (Fresh)

![CI workflow](https://github.com/bamnet/concerto-fresh/actions/workflows/ci.yml/badge.svg)

Concerto (fresh) is an experiment in radically simplifying Concerto 2 to
enable long-term support and easy maintance.

## Installation

There are two ways to install Concerto: using Docker (recommended) or from the Git repository.

### Option 1: Docker (Recommended)

The easiest way to get Concerto running is with Docker.

#### Steps

```shell
docker pull ghcr.io/bamnet/concerto:latest

# If you need to generate a secret
docker run --rm ghcr.io/bamnet/concerto:latest bin/rails secret

docker run -d \
     -p 80:80 \
     -e SECRET_KEY_BASE=<your-generated-secret> \
     -v concerto_storage:/rails/storage \
     --name concerto \
     ghcr.io/bamnet/concerto:latest
```

Open your browser and navigate to `http://localhost`.

#### Configuration Options

| Environment Variable | Description                                   | Default |
| -------------------- | --------------------------------------------- | ------- |
| `SECRET_KEY_BASE`    | Secret key for encrypting sessions (required) | -       |
| `RAILS_MAX_THREADS`  | Maximum number of threads                     | 5       |
| `DISABLE_SSL`        | Set this to allow non-SSL access              | -       |


## Development

To start a local development server:

```shell
bin/dev
```

Misc Notes:

- We use ImportMaps to manage JS deps. Add dependencies using a command like `bin/importmap pin @stimulus-components/dropdown`
- Needs icons? Copy and paste SVG from https://heroicons.com/.

### Testing

Unit tests:

```shell
bin/rails test
```

System tests:

```shell
bin/rails test:system
```

Frontend tests:

```shell
yarn run vitest
```
