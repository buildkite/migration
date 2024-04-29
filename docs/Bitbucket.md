# Bitbucket Pipelines

The Buildkite Migration tool's currently supported (✅), partially supported (⚠️) and unsupported (❌) properties in translation of Bitbucket pipelines to Buildkite pipelines are listed below.

### Clone (`clone`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `clone` | ❌ | Clone options for all steps of a Bitbucket Pipeline. These options should be set on a Buildkite agent itself via [configuration](https://buildkite.com/docs/agent/v3/configuration) of properties such as the clone flags (`git-clone-flags`, `git-clone-mirror-flags` if utilising a Git mirror), fetch flags (`git-fetch-flags`) - or changing the entire checkout process in a customised [plugin](https://buildkite.com/docs/plugins/writing) overriding the default agent `checkout` hook. |

### Definitions (`definitions`)

| Key | Supported? | Notes |
| --- | --- | --- |

### Image (`image`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `image` | ✅ | The container image that is to be applied for each step within a Bitbucket Pipeline. Images set at this level will be applied to all steps within a Buildkite pipeline, utilising the specified image within the [docker-buildkite-plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). This has lower precedence over per-step `image` configuration (see `pipelines.default.step.image`). |

### Options (`options`)

| Key | Supported? | Notes |
| --- | --- | --- |

### Pipelines (`pipelines`)

| Key | Supported? | Notes |
| --- | --- | --- |

| `pipelines.default.step.clone` | ❌ | Clone options for a specific step of a Bitbucket Pipeline. These options should be set on a Buildkite agent itself via [configuration](https://buildkite.com/docs/agent/v3/configuration) of properties such as the clone flags (`git-clone-flags`, `git-clone-mirror-flags` if utilising a Git mirror), fetch flags (`git-fetch-flags`) - or changing the entire checkout process in a customised [plugin](https://buildkite.com/docs/plugins/writing) overriding the default agent `checkout` hook. |
| `pipelines.default.step.image` | ✅ | The container image that is to be applied for a specific step within a Bitbucket Pipeline. Images set at this level will be applied irrespective of the pipeline-level `image` key that is set, and will be applied in the corresponding Buildkite pipeline using the [docker-buildkite-plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). |
| `pipelines.default.step.name` | ✅ | The name of a specific step within a Bitbucket Pipeline. Translates to a Buildkite command step's `label`. |
| `pipelines.default.step.script` | ✅ | The individual commands that make up a specific step. Each is translated into a singular command within the `commands` key of a Buildkite command step. |