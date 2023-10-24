# CircleCI

The Buildkite Migration tool's currently supported, partially supported and unsupported properties in translation CircleCI pipelines to Buildkite pipelines are listed below:

## Supported properties

### aliases

An `alias` is a definition of a reusable snippet of a CircleCI pipeline. Defined with a `&` (anchor) - these are then substituted into the required section of the pipeline with `*`: for example, `*tests`.

The Buildkite Migration tool supports reading configuration defined from anchors and utilised through the use of an `alias`.

### commands

A `command` defined in a CircleCI pipeline is a reusable set of instructions with parameters that can be inserted into required `job` executions. Commands can have their own set list of `steps` that are translated through to the generated [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands`. If a `command` contains a `parameters` key, they are respected when used in jobs/workflows and their defaults values used when not specified.

### workflows

A CircleCI `workflow` is a collection of `jobs`, whose ordering defines how a CircleCI pipeline is run. Workflows can be specified to run its collection of `jobs` sequentially, or in parallel, and allows for specifying dependencies (requirements) between each `workflow` that is configured.  

Each `job` that is defined as part of a `workflow` within a CircleCI pipeline will be transitioned to a Buildkite [command step](https://buildkite.com/docs/pipelines/command-step) within the generated pipeline. If a CircleCI pipeline has more than 1 `workflow` specified, each will be transitioned to a [group step](https://buildkite.com/docs/pipelines/group-step). The Buildkite Migration tool supports the use of `filters`: and specifically, both of `branches` and `tags` to set a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps) in the generated pipeline.

## Partially supported properties 

### jobs

CircleCI `jobs` are a collection of steps that are run on a single worker unit: whether that is on a host directly, or on a virtualised host (such as within a Docker container). 

The Buildkite Migration tool currently supports the following keys relative to CircleCI `jobs`:

#### General

- `environment`: The `job` level environment variables of a CircleCI pipeline. Applied in the generated [command step](https://buildkite.com/docs/pipelines/command-step) as [step level](https://buildkite.com/docs/pipelines/environment-variables#runtime-variable-interpolation) environment variables with the `env` key.
- `parameters`: Reusable keys that are used within `step` definitions within a `job`. Default parameters that are specified in a `parameters` block are passed through into the [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands` if specified.
- `steps`: A collection of commands that are executed as part of a CircleCI `job`. Steps can be defined within an `alias`. All `steps` within a singular `job` are translated to the `commands` of a shared [command step](https://buildkite.com/docs/pipelines/command-step) within the generated Buildkite pipeline to ensure they share the same execution environment.
- `working_directory`: The location of the executor where steps are run in. If set, a change directory (`cd`) command is created within the shared `commands` of a Buildkite [command step](https://buildkite.com/docs/pipelines/command-step) to the desired location.

#### Docker (Execution Environment)

- `docker`: Specifies that the `job` will run within a Docker container (by its `image` property) with the use of the [Docker Buildkite Plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). Additionally, the [Docker Login Plugin](https://github.com/buildkite-plugins/docker-login-buildkite-plugin) is appended if an `auth` property is defined, or the [ECR Buildkite Plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin) if an `aws-auth` property is defined within the `docker` property. Sets the [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step) to `executor_type: docker`.

#### Machine (Execution Environment)

- `machine`: Specifies that the `job` will run on a machine execution environment. This translates to [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step) through the tags of `executor_type: machine` and `executor_image: self-hosted`.
- `resource_class`: The specification of compute that the executor will require in running a job. This is used to specify the `resource_class` [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tag for the corresponding [command step](https://buildkite.com/docs/pipelines/command-step).

#### macOS (Execution Environment)

- `macos`: Specifies that the `job` will run on a macOS bases execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: osx`, as well as the specified version of `xcode` from the `macos` parameters as `executor_xcode: <version>`.

#### Windows (Execution Environment)

- `windows`: Specifies that the `job` will run on a Windows based execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: windows`.

#### Unsupported properties

The following `job` parameters are currently not supported by the Buildkite Migration tool:

- `branches`: The `branches` that will be allowed/blocked for a singular `job`. Presently, the Buildkite Migration tool supports setting `filters` in `workflows`: and in particular, `branches` and `tags` sub-properties in setting a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps) in the generated pipeline.
- `executors`: The `executor` key is currently not supported. The execution environment in Buildkite is defined by the [queues](https://buildkite.com/docs/agent/v3/queues#setting-an-agents-queue) and [tags](https://buildkite.com/docs/agent/v3/cli-start#setting-tags) applied to an agent, and [targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) them when creating builds.
- `parallelism`: A `parallelism` parameter (if defined greater than 1) will create a seperate execution environment and will run the `steps` of the specific `job` in parallel. In Buildkite - a similar `parallelism` key can be set to a [command step](https://buildkite.com/docs/tutorials/parallel-builds#parallel-jobs) which will run the defined `command` over seperate jobs (sharing the same agent [queues](https://buildkite.com/docs/agent/v3/queues#setting-an-agents-queue)/[tags](https://buildkite.com/docs/agent/v3/cli-start#setting-tags) targets).
- `shell`: The `shell` property sets the default shell that is used across all commands within all steps. This should be configured on the agent - or by defining the `shell` [option](https://buildkite.com/docs/agent/v3/cli-start#shell) when starting a Buildkite agent: which will set the shell command used to interpret all build commands.

## Unsupported properties (No direct translation)

### orbs

A `orb` within CircleCI is a reusable piece of configuration that can be utilised within a CircleCI pipeline - and often used for third party integration and tasks associated with the services capability.

Orbs are currently not supported by the Buildkite Migration tool, and should be translated by hand if required to utilise within a Buildkite pipeline. The Buildkite platform has reusable [plugins](https://buildkite.com/docs/plugins/directory) that provide a similar experience for integrating various common (and third party integration) tasks throughout a Buildkite pipeline, such as [logging into ECR](https://github.com/buildkite-plugins/ecr-buildkite-plugin), running a step within a [Docker container](https://github.com/buildkite-plugins/docker-buildkite-plugin), running multiple Docker images through a [compose file](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin), triggering builds in a [monorepo setup](https://github.com/buildkite-plugins/monorepo-diff-buildkite-plugin) and many more.

Additionally, an approach to assist in configuring reusable pieces of configuration within a Buildkite pipeline is through the use of [YAML anchors](https://buildkite.com/docs/plugins/using#using-yaml-anchors-with-plugins) - which are defined and used in a similar way to CircleCI `aliases`. 