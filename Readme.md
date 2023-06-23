# Buildkite Migration tool

A tool to transform pipelines from other CI providers to Buildkite.

```shell
$ cat examples/circleci/basic.yml
version: 2
jobs:
  build:
    docker:
      - image: circleci/python:3.6.2-stretch-browsers
    steps:
      - checkout
      - run: pip install -r requirements/dev.txt

$ buildkite-compat examples/circleci/basic.yml
steps:
- label: ":circleci: build"
  key: "build"
  commands:
    - "sudo cp -R /buildkite-checkout /home/circleci/checkout"
    - "sudo chown -R circleci:circleci /home/circleci/checkout"
    - "cd /home/circleci/checkout"
    - "pip install -r requirements/dev.txt"
  plugins:
  - docker#v3.3.0:
      image: "circleci/python:3.6.2-stretch-browsers"
      workdir: "/buildkite-checkout"
```

Note that setting the environment variable `BUILDKITE_PLUGIN_<UPPERCASE_NAME>_VERSION` will override the default version of the plugins used. For example:

```
$ BUILDKITE_PLUGIN_DOCKER_VERSION=testing-branch buildkite-compat examples/circleci/basic.yml
steps:
- label: ":circleci: build"
  key: "build"
  commands:
    - "sudo cp -R /buildkite-checkout /home/circleci/checkout"
    - "sudo chown -R circleci:circleci /home/circleci/checkout"
    - "cd /home/circleci/checkout"
    - "pip install -r requirements/dev.txt"
  plugins:
  - docker#testing-branch:
      image: "circleci/python:3.6.2-stretch-browsers"
      workdir: "/buildkite-checkout"
```

## API Service

Buildkite Compat can also be used via a HTTP API:

```shell
$ curl -X POST -F 'file=@examples/circleci/basic.yml' https://buildkite-compat.herokuapp.com
steps:
- label: ":circleci: build"
  key: build
  commands:
  - sudo cp -R /buildkite-checkout /home/circleci/checkout
  - sudo chown -R circleci:circleci /home/circleci/checkout
  - cd /home/circleci/checkout
  - pip install -r requirements/dev.txt
  plugins:
  - docker#v3.3.0:
      image: circleci/python:3.6.2-stretch-browsers
      workdir: "/buildkite-checkout"
```

The output can be piped directly into a `buildkite-agent pipeline upload` command:

```shell
$ curl -X POST -F 'file=@.circleci/config.yml' https://buildkite-compat.herokuapp.com | buildkite-agent pipeline upload
```

## Release

```bash
# This needs to be installed first https://github.com/pmq20/ruby-packer
curl -L http://enclose.io/rubyc/rubyc-darwin-x64.gz | gunzip > rubyc
chmod +x rubyc
mv /usr/local/bin

# Prepare release folders
rm -rf dist
mkdir dist
rubyc bin/buildkite-compat -o dist/buildkite-compat
```
