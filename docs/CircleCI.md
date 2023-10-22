# CircleCI

The Buildkite Migration tool's currently supported, partially supported and unsupported properties in translation CircleCI pipelines to Buildkite pipelines are listed below:

## Supported properties

### aliases

An `alias` is a definition of a reusable snippet of a CircleCI pipeline. Defined with a `&` (anchor) - these are then substituted into the required section of the pipeline with `*`: for example, `*tests`.

The Buildkite Migration tool supports reading configuration defined from anchors and utilised through the use of an `alias`.

### commands

A `command` defined in a CircleCI pipeline is a reusable set of instructions with parameters that can be inserted into required `job` executions. Commands can have their own set list of `steps` that are translated through to the generated [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands`. If a `command` contains a `parameters` key, its default parameters that is specified within the block is passed through into the specific command if it is utilised.

### workflows

A CircleCI `workflow` is a collection of `jobs`, whose ordering defines how a CircleCI pipeline is run. Workflows can be specified to run its collection of `jobs` sequentially, or in parallel, and allows for specifying dependencies (requirements) between each `workflow` that is configured. 

Each `job` that is defined as part of a `workflow` within a CircleCI pipeline will be transitioned to a Buildkite [command step](https://buildkite.com/docs/pipelines/command-step) within the generated pipeline.

## Partially supported properties 

### jobs

CircleCI `jobs` are a collection of steps that are run on a single worker unit: whether that is on a host directly, or on a virtualised host (such as within a Docker container). 

The Buildkite Migration tool currently supports the following keys relative to CircleCI `jobs`:

#### General

- `environment`: The `job` level environment variables of a CircleCI pipeline. Applied in the generated [command step](https://buildkite.com/docs/pipelines/command-step) as [step level](https://buildkite.com/docs/pipelines/environment-variables#runtime-variable-interpolation) environment variables with the `env` key.
- `parameters`: Reusable keys that are used within `step` definitions within a `job`. Default parameters that are specified in a `parameters` block are passed through into the [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands` if specified.
- `steps`: A collection of commands that are executed as part of a CircleCI `job`. Steps can be defined within an `alias`.

#### Docker

- `docker`: Specifies that the `job` will run within a Docker container (by its `image` property). Translates to the use of the [Docker Buildkite Plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin) with the specified image defined - and additionally: the [Docker Login Plugin](https://github.com/buildkite-plugins/docker-login-buildkite-plugin) and the [ECR Buildkite Plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin) if `auth` or `aws-auth` is specified in the `docker` parameter respectfully. The [Docker Compose Buildkite Plugin](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin) will need to be used for multi-container `jobs`. Sets the [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step) to `executor_type: docker`.

#### Machine 

- `machine`: Specifies that the `job` will run on a machine execution environment. The `resource_class` parameter will be utilised to specify [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step), in addition to setting the additional tags of ``executor_type: machine` and `executor_image: self-hosted`.
- `resource_class`: The specification of compute that the executor will require in running a job. This is used to specify the `resource_class` [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tag for the corresponding [command step](https://buildkite.com/docs/pipelines/command-step).

#### macOS 

- `macos`: Specifies that the `job` will run on a macOS bases execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: osx`, as well as the specified version of `xcode` from the `macos` parameters as `executor_xcode: <version>`.

#### Windows

- `windows`: Specifies that the `job` will run on a Windows based execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: windows`.

Currently, these following `job` parameters are not supported by the Buildkite Migration tool:

- `executors`: The `executor` key is currently not supported yet (Supported keys for `job` execution environments are `docker`, `machine`, `macos` and `windows`).

## Unsupported properties (No direct translation)

### orbs

A `orb` within CircleCI is a reusable piece of configuration that can be utilised within a CircleCI pipeline - and often used for third party integration and tasks associated with the services capability.

Orbs are currently not supported by the Buildkite Migration tool, and should be translated by hand if required to utilise within a Buildkite pipeline. The Buildkite platform has reusable [plugins](https://buildkite.com/docs/plugins/directory) that provide a similar experience for integrating various common (and third party integration) tasks throughout a Buildkite pipeline, such as [logging into ECR](https://github.com/buildkite-plugins/ecr-buildkite-plugin), running a step within a [Docker container](https://github.com/buildkite-plugins/docker-buildkite-plugin), running multiple Docker images through a [compose file](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin), triggering builds in a [monorepo setup](https://github.com/buildkite-plugins/monorepo-diff-buildkite-plugin) and many more.

Additionally, an approach to assist in configuring reusable pieces of configuration within a Buildkite pipeline is through the use of [YAML anchors](https://buildkite.com/docs/plugins/using#using-yaml-anchors-with-plugins) - which are defined and used in a similar way to CircleCI `aliases`. 