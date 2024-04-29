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
| `pipelines.default.step.deployment` | ❌ | The environment set for the Bitbucket Deployments dashboard. This has no translatable equivalent within Buildkite. |
| `pipelines.default.step.fail-fast` | ❌ | Whether a specific step of a Bitbucket Pipeline allows a parallel step to fail entirely if it fails (set as `true`), or allows failures (set as `false`). Consider using a combination of `soft_fail` and/or `cancel_on_build_failing` in the corresponding Buildkite command steps' [attributes](https://buildkite.com/docs/pipelines/command-step#command-step-attributes) for a similar [approach](https://buildkite.com/docs/pipelines/command-step#fail-fast). |
| `pipelines.default.step.image` | ✅ | The container image that is to be applied for a specific step within a Bitbucket Pipeline. Images set at this level will be applied irrespective of the pipeline-level `image` key that is set, and will be applied in the corresponding Buildkite pipeline using the [docker-buildkite-plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). |
| `pipelines.default.step.max-time` | ✅ | The maximum allowable time that a step within a Bitbucket Pipeline is able to run for. Translates to the corresponding Buildkite pipelines' command step `timeout_in_minutes` attribute. |
| `pipelines.default.step.name` | ✅ | The name of a specific step within a Bitbucket Pipeline. Translates to a Buildkite command step's `label`. |
| `pipelines.default.step.runs-on` | ✅ | Allocating the Bitbucket Pipeline to run on a self-hosted runner with the specific label. All `runs-on` values will be set as agent [tags](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) in the Buildkite command step for targeting on specific Buildkite agents within an organization. |
| `pipelines.default.step.script` | ✅ | The individual commands that make up a specific step. Each is translated into a singular command within the `commands` key of a Buildkite command step. |
| `pipelines.default.step.size` | ✅ | Allocation of sizing options for the given memory for a specific step within a Bitbucket Pipeline. The `size` value will be set as an agent [tag](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) in the Buildkite command step for targeting on specific Buildkite agents within an organization. |