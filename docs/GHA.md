# GitHub Actions

The Buildkite Migration tool supports transforming GitHub Action pipeline definitions to Buildkite pipelines.

## Supported properties








## Partially supported properties

### concurrency

The `concurrency` key within a GitHub Action workflow can be defined at topmost level, and within a single job. The Buildkite Migration tool supports the translation of the `concurrency` key (and `group`/`cancel-in-progress`) in job definitions: and maps to the `concurrency_group` [key](https://buildkite.com/docs/pipelines/controlling-concurrency#concurrency-groups) available within Buildkite. Buildkite also allows a upper limit on how much jobs are created through a single step definition with the `concurrency` key: which is set as `1` by default (there isn't a translatable key within a GitHub Action workflow).

The `cancel-in-progress` Boolean value that can be definied in a `concurrency` hash inside a GitHub Action job workflow maps to the Buildkite pipeline setting of [Cancel Intermediate Builds](https://buildkite.com/docs/pipelines/skipping#cancel-running-intermediate-builds) - which can be set within a pipeline's settings page, or when creating/updating a pipeline via the [REST](https://buildkite.com/docs/apis/rest-api/pipelines#create-a-yaml-pipeline)/[GraphQL](https://buildkite.com/docs/apis/graphql/schemas/mutation/pipelinecreate) APIs.

## Unsupported properties

### name

The `name` key sets the name of the action as it will appear in the GitHub repositorys' "Actions" tab. When creating a Buildkite pipeline, it's name is set through the UI when first creating the pipeline - and can be altered within its pipeline settings, or via the [REST](https://buildkite.com/docs/apis/rest-api/pipelines#update-a-pipeline) or [GraphQL](https://buildkite.com/docs/apis/graphql/schemas/input-object/pipelineupdateinput) APIs.

### on

The `on` key allows for triggering a GitHub Action workflow. In Builkdite pipelines - this capability is defined within a `trigger` [step](https://buildkite.com/docs/pipelines/trigger-step) - where utilized within a pipeline, will create a build on the specified pipeline with additional properties.

### permissions

Within GitHub Action workflows, a `permissions` key allows the permission of the `GITHUB_TOKEN` to be modified with additional or removed access as required. 

### run_name

This key sets the name of a GitHub Action workflow's run. Within Buildkite - when pipeline builds are created - a build message can be specified (contained in each job's environment as `BUILDKITE_MESSAGE`). The value is empty when a message is not set - and on events from source control, is the commit's title. A build message can also be set when creating a build through the [REST](https://buildkite.com/docs/apis/rest-api/builds#create-a-build) and [GraphQL](https://buildkite.com/docs/apis/graphql/schemas/mutation/buildcreate) APIs.