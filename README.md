# Concerto (Fresh)

![CI workflow](https://github.com/bamnet/concerto-fresh/actions/workflows/ci.yml/badge.svg)

Concerto (fresh) is an experiment in radically simplifying Concerto 2 to
enable long-term support and easy maintance.

## Development

To start a local development server:

```shell
bin/dev
```

Misc Notes:

* We use ImportMaps to manage JS deps.  Add dependencies using a command like `bin/importmap pin @stimulus-components/dropdown`

### Testing

Unit tests:


```shell
bin/rails test
```

System tests:

```shell
bin/rails test:system
```