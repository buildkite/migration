# CircleCI

### Logical/Helper Keys

| Key | Supported? | Notes |
| --- | --- | --- |
| `aliases` | 🟢 | A list of reusable YAML snippets of a CircleCI pipeline.
| `aliases.&<name>` | 🟢 | A singular alias describing a resusable snippet of YAML to apply to a specific point in a CircleCI pipeline. Defined with a `&` (anchor) - these blocks are substituted into configuration with `*`: for example, `*tests`.

### Commands (`commands`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `commands` | 🟢 | A `command` defined in a CircleCI pipeline is a reusable set of instructions with parameters that can be inserted into required `job` executions. Commands can have their own set list of `steps` that are translated through to the generated [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands`. If a `command` contains a `parameters` key, they are respected when used in jobs/workflows and their defaults values used when not specified. |

### Executors (`executors`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `executors` | 🔴 | : The `executor` key is currently not supported. The execution environment in Buildkite is defined by the [queues](https://buildkite.com/docs/agent/v3/queues#setting-an-agents-queue) and [tags](https://buildkite.com/docs/agent/v3/cli-start#setting-tags) applied to an agent, and [targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) them when creating builds. |

### Jobs (`jobs)

| Key | Supported? | Notes |
| --- | --- | --- |
| `jobs` | 🟢 | A collection of steps that are run on a single worker unit: whether that is on a host directly, or on a virtualised host (such as within a Docker container). Orchestrated with `workflows`. |
| `jobs.<name>` | 🟢 | A named induvidual `job` that makes up part of a given `workflow`. |
| `jobs.<name>.docker` | 🟢 | Specifies that the `job` will run within a Docker container (by its `image` property) with the use of the [Docker Buildkite Plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). Additionally, the [Docker Login Plugin](https://github.com/buildkite-plugins/docker-login-buildkite-plugin) is appended if an `auth` property is defined, or the [ECR Buildkite Plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin) if an `aws-auth` property is defined within the `docker` property. Sets the [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step) to `executor_type: docker`. |
| `jobs.<name>.environment` | 🟢 | The `job` level environment variables of a CircleCI pipeline. Applied in the generated [command step](https://buildkite.com/docs/pipelines/command-step) as [step level](https://buildkite.com/docs/pipelines/environment-variables#runtime-variable-interpolation) environment variables with the `env` key. |
| `jobs.<name>.macos` | 🟢 | Specifies that the `job` will run on a macOS bases execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: osx`, as well as the specified version of `xcode` from the `macos` parameters as `executor_xcode: <version>`. |
| `jobs.<name>.machine` | 🟢 | Specifies that the `job` will run on a machine execution environment. This translates to [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) for the generated [command step](https://buildkite.com/docs/pipelines/command-step) through the tags of `executor_type: machine` and `executor_image: self-hosted`. |
| `jobs.<name>.parallelism` | 🔴 | A `parallelism` parameter (if defined greater than 1) will create a seperate execution environment and will run the `steps` of the specific `job` in parallel. In Buildkite - a similar `parallelism` key can be set to a [command step](https://buildkite.com/docs/tutorials/parallel-builds#parallel-jobs) which will run the defined `command` over seperate jobs (sharing the same agent [queues](https://buildkite.com/docs/agent/v3/queues#setting-an-agents-queue)/[tags](https://buildkite.com/docs/agent/v3/cli-start#setting-tags) targets). |
| `jobs.<name>.parameters` | 🟢 | Reusable keys that are used within `step` definitions within a `job`. Default parameters that are specified in a `parameters` block are passed through into the [command step](https://buildkite.com/docs/pipelines/command-step)'s `commands` if specified. |
| `jobs.<name>.resource_class` | 🟢 | The specification of compute that the executor will require in running a job. This is used to specify the `resource_class` [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tag for the corresponding [command step](https://buildkite.com/docs/pipelines/command-step). |
| `jobs.<name>.shell` | 🔴| The `shell` property sets the default shell that is used across all commands within all steps. This should be configured on the agent - or by defining the `shell` [option](https://buildkite.com/docs/agent/v3/cli-start#shell) when starting a Buildkite agent: which will set the shell command used to interpret all build commands. |
| `jobs.<name>.steps` | 🟢 | A collection of commands that are executed as part of a CircleCI `job`. Steps can be defined within an `alias`. All `steps` within a singular `job` are translated to the `commands` of a shared [command step](https://buildkite.com/docs/pipelines/command-step) within the generated Buildkite pipeline to ensure they share the same execution environment. |
| `jobs.<name>.windows` | 🟢 | Specifies that the `job` will run on a Windows based execution environment. The [agent targeting](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) tags for the generated [command step](https://buildkite.com/docs/pipelines/command-step) will be set to `executor_type: windows`. |
| `jobs.<name>.working_directory` | 🟢 | The location of the executor where steps are run in. If set, a change directory (`cd`) command is created within the shared `commands` of a Buildkite [command step](https://buildkite.com/docs/pipelines/command-step) to the desired location. |


### Orbs (`orbs`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `orbs` | 🔴 | Orbs are currently not supported by the Buildkite Migration tool, and should be translated by hand if required to utilise within a Buildkite pipeline. The Buildkite platform has reusable [plugins](https://buildkite.com/docs/plugins/directory) that provide a similar experience for integrating various common (and third party integration) tasks throughout a Buildkite pipeline, such as [logging into ECR](https://github.com/buildkite-plugins/ecr-buildkite-plugin), running a step within a [Docker container](https://github.com/buildkite-plugins/docker-buildkite-plugin), running multiple Docker images through a [compose file](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin), triggering builds in a [monorepo setup](https://github.com/buildkite-plugins/monorepo-diff-buildkite-plugin) and more. |

### Parameters (`parameters`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `parameters` | 🔴 | Pipeline-level parameters that allow for utilisation in the pipeline level configuration. Pipeline level [environment variables](https://buildkite.com/docs/pipelines/environment-variables#defining-your-own) allow for utilising variables in Buildkite pipeline configuration with [conditionals](https://buildkite.com/docs/pipelines/conditionals). |

### Setup (`setup`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `setup` | 🔴 | Allows for the conditional configuration trigger from outside the .circleci directory - not applicable with Buildkite. Buildkite offers [trigger steps](https://buildkite.com/docs/pipelines/trigger-step) that allow for triggering builds from another pipeline. |

### Version (`version`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `version` | 🔴 | The version of the CircleCI pipeline configuration applied to this pipeline. No equivalent mapping exists in Buildkite. Attributes for required and optional attributes in the various step types supported in Buildkite are listed in the [docs](https://buildkite.com/docs/pipelines/step-reference). |

### Workflows (`workflows`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `workflows` | 🟢 | A a collection of `jobs`, whose ordering defines how a CircleCI pipeline is run. |
| `workflows.<name>` | 🟢 | An induvidual named workflow that makes up part of the CircleCI pipeline's definition. If a CircleCI pipeline has more than 1 `workflow` specified, each will be transitioned to a [group step](https://buildkite.com/docs/pipelines/group-step). |
| `workflows.<name>.jobs` | 🟢 | Induvidual named `jobs` that make up part of this specific workflow. Each `job` that is defined as part of a `workflow` within a CircleCI pipeline will be transitioned to a Buildkite [command step](https://buildkite.com/docs/pipelines/command-step) within the generated pipeline. |
| `workflows.<name>.jobs.<name>.branches` | 🔴 | The `branches` that will be allowed/blocked for a singular `job`. Presently, the Buildkite Migration tool supports setting `filters` within `workflows`: and in particular, `branches` and `tags` sub-properties in setting a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps) in the generated pipeline. |
| `workflows.<name>.jobs.<name>.filters` | 🟢 | The `branches` and `tag` filters that will determine the eligibility for a CircleCI to run. |
| `workflows.<name>.jobs.<name>.filters.branches`| 🟢 | The specific `branches` that are applicable to the `job`'s filter. Translated to a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps). |
| `workflows.<name>.jobs.<name>.filters.tags` | 🟢 |  The specific `tags` that are applicable to the `job`'s filter. Translated to a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps).|
| `workflows.<name>.jobs.<name>.requires` | 🟢 | A list of `jobs` that require this `job` to start. Translated to explicit [step dependencies](https://buildkite.com/docs/pipelines/dependencies#defining-explicit-dependencies) with the `depends_on` key. | 