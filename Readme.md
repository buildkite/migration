# Buildkite Migration tool

A tool to help kick start the transition of pipelines from other CI providers, to Buildkite.

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

Buildkite Compat can also be used via a HTTP API using `rackup` from the `app` folder of this repository.

```sh
docker compose up webui
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

## Translation results

Buildkite has its own suggested best practices, these may differ to those from other providers, check out the [Buildkite Docs](https://buildkite.com/docs) for more information. Review and use the results of this tool as the basis towards Buildkite adoption, the output of the migration tool is a guide and manual editing is likely to be required.

## Further Details 

Further information on the currently supported attributes of CI provider pipeline translation to Buildkite pipelines can be found below (within the `/docs` directory):

- [GitHub Actions](/docs/GHA.md)
- CircleCI