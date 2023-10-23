{{- define "s2i_doc" -}}
  {{- $s2iLanguage := index . 1 -}}
  {{- $s2iBuilderImage := index . 2 -}}
  {{- with index . 0 -}}
## Source-to-Image Tekton Tasks (`s2i-{{ $s2iLanguage }}`)

# Abstract

Describes the Tekton Task supporting Source-to-Image for {{ $s2iLanguage }}

# Abstract

The `s2i-{{ $s2iLanguage }}` Task helps in building reproducible container images from source code.

`s2i-{{ $s2iLanguage }}` Task is customized with the builder image for {{ $s2iLanguage }}.

Click [here]({{ $s2iBuilderImage }}) to know more about the builder image used for {{ $s2iLanguage }}.

# Usage

Please, consider the usage example below:


In case the Container Registry requires authentication, please consider the [Tekton Pipelines documentation][tektonPipelineAuth]. In a nutshell, you need to create a Kubernetes Secret describing the following attributes:

```bash
kubectl create secret docker-registry imagestreams \
  --docker-server="image-registry.openshift-image-registry.svc:5000" \
  --docker-username="${REGISTRY_USERNAME}" \
  --docker-password="${REGISTRY_TOKEN}"
```

Then make sure the Secret is linked with the Service-Account running the `TaskRun`/`PipelineRun`.

## Workspaces

s2i-{{ $s2iLanguage }} task uses the `source` workspace which is meant to contain the Application source code, it also acts as the build context for S2I workflow.

## Params

| Param             | Type   | Default                  | Description                                                               |
| ----------------- | ------ | ------------------------ | ------------------------------------------------------------------------- |
| IMAGE             | string | (required)               | Fully qualified container image name to be built by s2i                   |
| IMAGE_SCRIPTS_URL | string | image:///usr/libexec/s2i | URL containing the default assemble and run scripts for the builder image |
| ENV_VARS          | array  | []                       | Array containing string of Environment Variables as "KEY=VALUE”           |
| SUBDIRECTORY      | string | .                        | Relative subdirectory to the source Workspace for the build-context.      |
| STORAGE_DRIVER    | string | overlay                  | Set buildah storage driver to reflect the currrent cluster node's         |
| settings.         |
| BUILD_EXTRA_ARGS  | string |                          | Extra parameters passed for the build command when building images.       |
| PUSH_EXTRA_ARGS   | string |                          | Extra parameters passed for the push command when pushing images.         |
| SKIP_PUSH         | string | false                    | Skip pushing the image to the container registry.                         |
| TLS_VERIFY        | string | true                     | Sets the TLS verification flag, true is recommended.                      |
| VERBOSE           | string | false                    | Turns on verbose logging, all commands executed will be printed out.      |

## Results

| Result       | Description                     |
| ------------ | ------------------------------- |
| IMAGE_URL    | Fully qualified image name.     |
| IMAGE_DIGEST | Digest of the image just built. |
  {{- end -}}
{{- end -}}
