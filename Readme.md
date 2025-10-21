# Buildkite Migration tool [![Build status](https://badge.buildkite.com/5db82bf94b2c528cb9723cdd222b60baca00c6328265c8427c.svg)](https://buildkite.com/buildkite/migration-tool)

The Buildkite migration tool serves as a compatibility layer, enabling the conversion of your existing CI configurations into a format compatible with Buildkite's pipeline definitions.

You can start the translation of your pipelines from other CI providers to Buildkite Pipelines by seeing how workflows from other CI/CD platforms map to the Buildkite Pipelines' concepts and architecture. Rather than serving as a complete automated migration solution, the Buildkite migration tool demonstrates how configurations from these other CI/CD platforms could be structured in a Buildkite pipeline configuration format.

```shell
$ buildkite-compat examples/circleci/legacy.yml
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#v5.7.0:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

Note: Setting the environment variable `BUILDKITE_PLUGIN_<UPPERCASE_NAME>_VERSION` will override the default version of the plugins used. For example:

```shell
$ BUILDKITE_PLUGIN_DOCKER_VERSION=testing-branch buildkite-compat examples/circleci/legacy.yml
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#testing-branch:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

## Web Service/API

Buildkite Compat can also be used via a HTTP API using `puma` from the `app` folder of this repository.

You start the web UI with either of the following docker commands:

```sh
docker compose up webui
```

Note: If you are using `docker run` you will have to override the entrypoint:

```shell
$ docker run --rm -ti -p 9292:9292 --entrypoint '' --workdir /app $IMAGE:$TAG puma --port 9292
```

After that, you can access a simple web interface at http://localhost:9292

![Web UI](docs/images/web-ui.png)

You can also programatically interact with it (maybe even pipe the output directly to `buildkite-agent pipeline upload`!):

```shell
$ curl -X POST -F 'file=@app/examples/circleci/legacy.yml' http://localhost:9292
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#v5.7.0:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

## Development

This project supports [mise](https://mise.jdx.dev/) for development environment management. To use mise:

```shell
# Install mise (if not already installed)
curl https://mise.run | sh

OR

brew install mise

# Configure mise to respect .ruby-version files
mise settings add idiomatic_version_file_enable_tools ruby

# Install Ruby version specified in .ruby-version
mise install
```

## Translation results

Buildkite has its own suggested best practices, these may differ to those from other providers, check out the [Buildkite Docs](https://buildkite.com/docs) for more information. Review and use the results of this tool as the basis towards Buildkite adoption, the output of the migration tool is a guide and manual editing is likely to be required.

## Further Details

Further information on the currently supported attributes of CI provider pipeline translation to Buildkite pipelines can be found in the official Buildkite Documentation:

- [GitHub Actions](https://buildkite.com/docs/pipelines/migration/tool/github-actions)
- [CircleCI](https://buildkite.com/docs/pipelines/migration/tool/circleci)
- [Bitbucket Pipelines](https://buildkite.com/docs/pipelines/migration/tool/bitbucket-pipelines)
