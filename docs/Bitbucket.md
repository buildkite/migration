# Bitbucket Pipelines

The Buildkite Migration tool's currently supported (✅), partially supported (⚠️) and unsupported (❌) properties in translation of Bitbucket pipelines to Buildkite pipelines are listed below.

### Clone (`clone`)

| Key | Supported? | Notes |
| --- | --- | --- |
| `clone` | ⚠️ | Clone options for all steps of a Bitbucket Pipeline. The majority of these options should be set on a Buildkite agent itself via [configuration](https://buildkite.com/docs/agent/v3/configuration) of properties such as the clone flags (`git-clone-flags`, `git-clone-mirror-flags` if utilising a Git mirror), fetch flags (`git-fetch-flags`) - or changing the entire checkout process in a customised [plugin](https://buildkite.com/docs/plugins/writing) overriding the default agent `checkout` hook. Sparse checkout options are supported (with the `sparse-checkout` sub-property) |

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
| `pipelines.branches` | ✅ | Branch configuration to apply certain Bitbucket Pipeline configuration based for specific branches. Translated to a [step conditional](https://buildkite.com/docs/pipelines/conditionals#conditionals-in-steps) in the corresponding Buildkite pipeline utilising the `build.branch`/`BUILDKITE_BRANCH` variable. |
| `pipelines.branches.<branch>` | ✅ | The branch name/wildcard to apply specific Bitbucket Pipeline step configuration within. |
| `pipelines.branches.<branch>.step` | ✅ | Step configuration for a specific branch within a Bitbucket Pipeline. See configuration options in this section (`pipelines.default.step.<attribute>`) for supported/unsupported attributes. |
| `pipelines.default.step.after-script` | ❌ | The actions that a Bitbucket Pipeline will undertake after the commands in the `script` key are run. For similar hehaviour, a [repository-level](https://buildkite.com/docs/agent/v3/hooks#hook-locations-repository-hooks) `pre-exit` hook approach will yield similar behaviour - running at the latter end of the [job lifecycle](https://buildkite.com/docs/agent/v3/hooks#job-lifecycle-hooks). |
| `pipelines.default.step.artifacts` | ✅ | Build artifacts that will be required for steps later in the Bitbucket Pipeline. Artifacts that are specified (whether one specific file, or multiple) will be set within the generated Buildkite pipeline's command step within the `artifact_paths` [key](https://buildkite.com/docs/pipelines/command-step). Each file found matching (or via glob syntax) will be uploaded to Buildkite's [Artifact storage](https://buildkite.com/docs/agent/v3/cli-artifact) that can be obtained in later steps. |
| `pipelines.default.step.caches` | ✅ | Step-level dependencies downloaded from external sources (Docker, Maven, PyPi for example) which will be able to be re-used in later Bitbucket Pipeline steps. Caches that are set at step level are translated in the corresponding Buildkite pipeline utilising the [cache-buildkite-plugin](https://github.com/buildkite-plugins/cache-buildkite-plugin) to store the downloaded dependencies for re-use between Buildkite builds. |
| `pipelines.default.step.condition` | ✅ | The configuration to prevent a Bitbucket Pipeline step from running unless the specific conditional is met. Translated to an inline conditional (`if`) within the corresponding Buildkite pipelines' command step's `commands` - based on a `git diff` of the base branch.|
| `pipelines.default.step.condition.changeset.includePaths` | ✅ | The specific file (or files) that need to be detected as changed for the `condition` to apply based. This can be set as specific files - or wildcards that match multiple files in a specific directory/directories. |
| `pipelines.default.step.clone` | ⚠️ | Clone options for a specific step of a Bitbucket Pipeline. The majority of these options should be set on a Buildkite agent itself via [configuration](https://buildkite.com/docs/agent/v3/configuration) of properties such as the clone flags (`git-clone-flags`, `git-clone-mirror-flags` if utilising a Git mirror), fetch flags (`git-fetch-flags`) - or changing the entire checkout process in a customised [plugin](https://buildkite.com/docs/plugins/writing) overriding the default agent `checkout` hook. Sparse checkout options are supported (with the `sparse-checkout` sub-property) |
| `pipelines.default.step.clone.sparse-checkout` | ✅ | Sparse-checkout option for a Bitbucket Pipeline step. Translated to utilising the [sparse-checkout-buildkite-plugin](https://github.com/buildkite-plugins/sparse-checkout-buildkite-plugin). |
| `pipelines.default.step.clone.sparse-checkout.code-mode` | ✅ | Whether the checkout patterns are considered to be a list of patterns (passed as the `--no-cone` flag to `git sparse-checkout` command). |
| `pipelines.default.step.clone.sparse-checkout.enabled` | ✅ | Whether sparse checkout is enabled for the Bitbucket Pipeline step. |
| `pipelines.default.step.clone.sparse-checkout.patterns` | ✅ | The list of paths to invoke a sparse checkout for. Can be a pattern to a specific file, directory, or wildcard for all files belonging within a certain directory. |
| `pipelines.default.step.deployment` | ❌ | The environment set for the Bitbucket Deployments dashboard. This has no translatable equivalent within Buildkite. |
| `pipelines.default.step.docker` | ❌ | The availability of docker in Bitbucket Pipelines steps. This will depend on the agent configuration that the corresponding Buildkite command step is being targeted to run said job has available. Consider [tagging](https://buildkite.com/docs/agent/v3/cli-start#tags) agents with `docker=true` to ensure Buildkite command steps requiring hosts with Docker installed and configured to accept/run specific jobs. |
| `pipelines.default.step.fail-fast` | ❌ | Whether a specific step of a Bitbucket Pipeline allows a parallel step to fail entirely if it fails (set as `true`), or allows failures (set as `false`). Consider using a combination of `soft_fail` and/or `cancel_on_build_failing` in the corresponding Buildkite command steps' [attributes](https://buildkite.com/docs/pipelines/command-step#command-step-attributes) for a similar [approach](https://buildkite.com/docs/pipelines/command-step#fail-fast). |
| `pipelines.default.step.image` | ✅ | The container image that is to be applied for a specific step within a Bitbucket Pipeline. Images set at this level will be applied irrespective of the pipeline-level `image` key that is set, and will be applied in the corresponding Buildkite pipeline using the [docker-buildkite-plugin](https://github.com/buildkite-plugins/docker-buildkite-plugin). |
| `pipelines.default.step.max-time` | ✅ | The maximum allowable time that a step within a Bitbucket Pipeline is able to run for. Translates to the corresponding Buildkite pipelines' command step `timeout_in_minutes` attribute. |
| `pipelines.default.step.name` | ✅ | The name of a specific step within a Bitbucket Pipeline. Translates to a Buildkite command step's `label`. |
| `pipelines.default.step.oidc` | ✅ | Open ID Connect configuration that will be applied for this Bitbucket Pipeline step. The generated command step in the corresponding Buildkite pipeline will [request](https://buildkite.com/docs/agent/v3/cli-oidc#request-oidc-token) an OIDC token and export it into the job environment as `BITBUCKET_STEP_OIDC_TOKEN` (to be passed to `sts` to assume an AWS role for example) |
| `pipelines.default.step.runs-on` | ✅ | Allocating the Bitbucket Pipeline to run on a self-hosted runner with the specific label. All `runs-on` values will be set as agent [tags](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) in the Buildkite command step for targeting on specific Buildkite agents within an organization. |
| `pipelines.default.step.script` | ✅ | The individual commands that make up a specific step. Each is translated into a singular command within the `commands` key of a Buildkite command step. |
| `pipelines.default.step.size` | ✅ | Allocation of sizing options for the given memory for a specific step within a Bitbucket Pipeline. The `size` value will be set as an agent [tag](https://buildkite.com/docs/pipelines/defining-steps#targeting-specific-agents) in the Buildkite command step for targeting on specific Buildkite agents within an organization. |
| `pipelines.default.step.trigger` | ✅ | The configuration setting the running a Bitbucket Pipeline step manually or automatically (latter being defaulted). For `manual` triggers - an [input step](https://buildkite.com/docs/pipelines/input-step) is inserted into the generated Buildkite pipeline before the specified `script` within a further command step. Explicit dependencies with `depends_on` are set between the two steps; requiring manual processing. |