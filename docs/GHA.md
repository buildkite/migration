# GitHub Actions

The Buildkite Migration tool supports transitioning GitHub Action workflow definitions to Buildkite pipelines.

## Partially supported properties

### concurrency

The `concurrency` key within a GitHub Action workflow can be defined at topmost level, and within a single job. The Buildkite Migration tool supports the transition of the `concurrency` key (and `group`/`cancel-in-progress`) in job definitions: and maps to the `concurrency_group` [key](https://buildkite.com/docs/pipelines/controlling-concurrency#concurrency-groups) available within Buildkite. Buildkite also allows a upper limit on how much jobs are created through a single step definition with the `concurrency` key: which is set as `1` by default (there isn't a translatable key within a GitHub Action workflow).

The `cancel-in-progress` Boolean value that can be defined in a `concurrency` hash inside a GitHub Action job workflow maps to the Buildkite pipeline setting of [Cancel Intermediate Builds](https://buildkite.com/docs/pipelines/skipping#cancel-running-intermediate-builds) - which can be set within a pipeline's settings page, or when creating/updating a pipeline via the [REST](https://buildkite.com/docs/apis/rest-api/pipelines#create-a-yaml-pipeline)/[GraphQL](https://buildkite.com/docs/apis/graphql/schemas/mutation/pipelinecreate) APIs.

### env 

GitHub Actions allows the specification of environment variables at the workflow level, at a `job` level, and for each `step` within a `job`.

Environment variables that are defined at the top of a workflow will be transition to [build level](https://buildkite.com/docs/pipelines/environment-variables#environment-variable-precedence) environment variables in the generated Buildkite pipeline. Environment variables defined within the context of each of a workflows' `jobs` are transitioned to [step level](https://buildkite.com/docs/pipelines/environment-variables#runtime-variable-interpolation) environment variables.

### jobs

GitHub Action workflows allows you to specify one or more `jobs` - main tasks of a workflow that run in parallel by default.

The Buildkite Migration tool currently supports the following 

- `runs_on`: The `runs_on` key defines the type of machine that the job will run on. Within Buildkite, this is mapped to an agent targeting [tag](https://buildkite.com/docs/agent/v3/queues#targeting-a-queue) of `runs_on`. Note that jobs that target custom `tag` names will have a `queue` target of `default`.
- `steps`: Steps that are defined for a particular `job`. Any `run` key is supported - and at present, any action that defines a `uses` attribute currently is not supported

## Unsupported properties

### defaults

A `defaults` key allows the definition of a hash in which configuration will apply to all of a workflow's jobs. 

While there isn't a direct transition from a GitHub Action workflow to a Buildkite pipeline - the Buildkite platform allows jobs to have default configuration applied to them through the use of [Agent](https://buildkite.com/docs/agent/v3/hooks#agent-lifecycle-hooks) or [Job](https://buildkite.com/docs/agent/v3/hooks#job-lifecycle-hooks) Lifecycle hooks. Agent lifecycle hooks allows the configuration of customized commands on agent start up and shut down. Job Lifecycle hooks allow for the customization of what occurs at each stage of a job's lifecycle - and can be specified and applied at an agent, repository or plugin level.

### name

The `name` key sets the name of the action as it will appear in the GitHub repositorys' "Actions" tab. When creating a Buildkite pipeline, it's name is set through the UI when first creating the pipeline - and can be altered within its pipeline settings, or via the [REST](https://buildkite.com/docs/apis/rest-api/pipelines#update-a-pipeline) or [GraphQL](https://buildkite.com/docs/apis/graphql/schemas/input-object/pipelineupdateinput) APIs.

### on

The `on` key allows for triggering a GitHub Action workflow. In Buildkite pipelines - this capability is defined within a `trigger` [step](https://buildkite.com/docs/pipelines/trigger-step) - where utilized within a pipeline, will create a build on the specified pipeline with additional properties.

### permissions

Within GitHub Action workflows, a `permissions` key allows the permission of the `GITHUB_TOKEN` to be modified with additional or removed access as required. Within Buildkite - [API Access Tokens](https://buildkite.com/docs/apis/managing-api-tokens) can be used within the context of a pipelines' build to interact with various Buildkite resources such as pipelines, artifacts, users, Test suites and more. Each token has a specified [token scope](https://buildkite.com/docs/apis/managing-api-tokens#token-scopes) that applies to interactions with the [REST](https://buildkite.com/docs/apis/rest-api) API, and can be configured with permission to interact with Buildkite's [GraphQL](https://buildkite.com/docs/apis/graphql-api) API.

### run_name

This key sets the name of a GitHub Action workflow's run. Within Buildkite - when pipeline builds are created - a build message can be specified (contained in each job's environment as `BUILDKITE_MESSAGE`). The value is empty when a message is not set - and on events from source control, is the commit's title. A build message can also be set when creating a build through the [REST](https://buildkite.com/docs/apis/rest-api/builds#create-a-build) and [GraphQL](https://buildkite.com/docs/apis/graphql/schemas/mutation/buildcreate) APIs.