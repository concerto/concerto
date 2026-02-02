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

#### Steps

```shell
docker pull ghcr.io/concerto/concerto:latest

# If you need to generate a secret
docker run --rm ghcr.io/concerto/concerto:latest bin/rails secret

docker run -d \
     -p 80:80 \
     -e SECRET_KEY_BASE=<your-generated-secret> \
     -v concerto_storage:/rails/storage \
     --name concerto \
     ghcr.io/concerto/concerto:latest
```

Open your browser and navigate to `http://localhost`.

#### Configuration Options

| Environment Variable | Description                                   | Default |
| -------------------- | --------------------------------------------- | ------- |
| `SECRET_KEY_BASE`    | Secret key for encrypting sessions (required) | -       |
| `RAILS_MAX_THREADS`  | Maximum number of threads                     | 5       |
| `DISABLE_SSL`        | Set this to allow non-SSL access              | -       |


## Development

Concerto can be developed on any machine that supports a standard Ruby on Rails development enviroment.
See the [Ruby on Rails documentation](https://guides.rubyonrails.org/index.html) for more information.
A devcontainer is also available for containerized development in supported platforms e.g. VSCode.

System Requirements:

* ruby 3.3
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
