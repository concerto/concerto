# Concerto Digital Signage System

![CI workflow](../../actions/workflows/ci.yml/badge.svg)
[![Website](https://img.shields.io/website?url=https%3A%2F%2Fdemo.concerto-signage.org%2Fup&label=demo%20instance)](https://demo.concerto-signage.org)

## What is Concerto?

Concerto is an open source digital signage system. Users submit graphic, textual, and other content, and moderators approve that content for use in a variety of content feeds which are displayed on screens connected to computers displaying the Concerto frontend.

Each screen has a template that has fields designated for content. The template can also have a background graphic and a CSS stylesheet. You can easily define your own templates.

A screen can subscribe its fields to feeds (or channels). Screens can be public or private (requiring a token).

Users can create content (an image, an iframe, video, rss content, etc.) and submit it to various feeds. The content can be scheduled for a specific date range. Content submitted to a feed can be ordered on that feed if desired. The default ordering is by content start date.

Feeds can be hidden or locked. Feeds belong to groups. If the user that submitted the content is an administrator or is authorized to moderate content on the feed based on their group membership permissions then the submission is automatically approved. Otherwise the content submission to the feed is pending a moderator’s approval.

A screen can define the content display rules for each field. This includes whether content should be displayed in order or randomly or based on priority. It can also designate the animation for transitions when content is swapped out and in.

### What's new in Concerto 3?

Concerto 3 is a re-write of Concerto 2, focused on long-term support and easy maintenance. It drops support for several features that were difficult to maintain during Rails upgrades (e.g. dynamic plugins) and focuses on core functionality closer to Concerto 1.

The Concerto 2 codebase can be found in the [2.x branch](https://github.com/concerto/concerto/tree/2.x).

## Installation

There are two ways to install Concerto: using Docker (recommended) or from the Git repository.

### Option 1: Docker (Recommended)

The easiest way to get Concerto running is with Docker.

#### Quick Start

```shell
# Generate a secret key (save this — you'll need it)
docker run --rm ghcr.io/concerto/concerto:latest bin/rails secret

# Start Concerto
docker run -d \
     --name concerto \
     -p 80:80 \
     -e SECRET_KEY_BASE=<your-generated-secret> \
     -e DISABLE_SSL=true \
     -v concerto_storage:/rails/storage \
     --restart unless-stopped \
     ghcr.io/concerto/concerto:latest
```

Open your browser and navigate to `http://localhost`.

> **Note:** The `DISABLE_SSL=true` flag is required if you are not using SSL locally or
> terminating upstream (e.g. via a reverse proxy or load balancer). Without it, Rails will
> attempt to enforce HTTPS and redirect all HTTP requests.

#### Docker Compose

For easier management, you can use Docker Compose. Create a `docker-compose.yml`:

```yaml
services:
  concerto:
    image: ghcr.io/concerto/concerto:latest
    ports:
      - "80:80"
    environment:
      SECRET_KEY_BASE: <your-generated-secret>  # generate with: docker run --rm ghcr.io/concerto/concerto:latest bin/rails secret
      DISABLE_SSL: true  # remove if using SSL termination upstream
    volumes:
      - concerto_storage:/rails/storage
    restart: unless-stopped

volumes:
  concerto_storage:
```

Then run:

```shell
docker compose up -d
```

#### Data Storage

Concerto stores all persistent data at `/rails/storage` inside the container,
including the SQLite database, job queue, cache, and uploaded files. You must
mount a volume to this path or data will be lost when the container is
recreated. **Back up this volume regularly.**

#### Configuration Options

| Environment Variable    | Description                                                       | Default |
| ----------------------- | ----------------------------------------------------------------- | ------- |
| `SECRET_KEY_BASE`       | Secret key for encrypting sessions (**required**)                 | -       |
| `DISABLE_SSL`           | Set to `true` to allow HTTP access without SSL                    | -       |
| `RAILS_MAX_THREADS`     | Maximum number of threads per Puma worker                         | 5       |
| `WEB_CONCURRENCY`       | Number of Puma worker processes                                   | 1       |
| `SOLID_QUEUE_IN_PUMA`   | Set to `false` to disable the in-process job worker               | true    |

Background job processing (Solid Queue) runs automatically inside the web
server process. For most single-server deployments, no separate worker
container is needed. Set `SOLID_QUEUE_IN_PUMA=false` if you want to run job
processing in a dedicated container.

Docker images are published for both amd64 and arm64 architectures, so
Concerto runs on Raspberry Pi and other ARM devices out of the box.

## Development

Concerto can be developed on any machine that supports a standard Ruby on Rails development enviroment.
See the [Ruby on Rails documentation](https://guides.rubyonrails.org/index.html) for more information.
A devcontainer is also available for containerized development in supported platforms e.g. VSCode.

System Requirements:

* ruby 3.4
* node, npm
* yarn, for the frontend
* libvips, for image resizing

Initial setup:

```shell
bundle install
yarn install
bin/rails db:setup
```

Starting a development server:

```shell
bin/dev
```

This will start a server accessible at http://localhost:3000.

Development Notes:

- As dependencies update, you'll probably need to run `bundle install && yarn install` regularly to keep up with dependabot.
- In the admin console (aka Rails views) we use ImportMaps to manage JS deps. Add dependencies using a command like `bin/importmap pin @stimulus-components/dropdown`.
- The frontend player is a Vite / Vue / Yarn app in `app/frontend` written in JavaScript. It does _not_ use ImportMaps.
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

Full CI suite:

```shell
bin/ci
```
