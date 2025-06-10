{{- /*

  Contains the common buildah task spec, to be embedded in both buildah and buildah-ns tasks.
  Takes a description parameter to allow different descriptions for each task.

*/ -}}
{{- define "spec_buildah" -}}
{{- $description := index . 1 -}}
{{- with index . 0 -}}
spec:
  description: |
{{ $description | nindent 4 }}

  workspaces:
    - name: source
      optional: false
      description: |
        Container build context, like for instnace a application source code
        followed by a `Dockerfile`.
    - name: dockerconfig
      description: >-
        An optional workspace that allows providing a .docker/config.json file
        for Buildah to access the container registry.
        The file should be placed at the root of the Workspace with name config.json
        or .dockerconfigjson.
      optional: true
    - name: rhel-entitlement
      description: >-
        An optional workspace that allows providing the entitlement keys
        for Buildah to access subscription. The mounted workspace contains
        entitlement.pem and entitlement-key.pem.
      optional: true
      mountPath: /tmp/entitlement
  params:
    - name: IMAGE
      type: string
      description: |
        Fully qualified container image name to be built by buildah.
    - name: DOCKERFILE
      type: string
      default: ./Dockerfile
      description: |
        Path to the `Dockerfile` (or `Containerfile`) relative to the `source` workspace.
    - name: BUILD_ARGS
      type: array
      default:
        - ""
      description: |
        Dockerfile build arguments, array of key=value

{{- include "params_buildah_common" . | nindent 4 }}
{{- include "params_common" . | nindent 4 }}

  results:
{{- include "results_buildah" . | nindent 4 }}

  stepTemplate:
    env:
{{- $variables := list
      "params.IMAGE"
      "params.CONTEXT"
      "params.DOCKERFILE"
      "params.FORMAT"
      "params.STORAGE_DRIVER"
      "params.BUILD_EXTRA_ARGS"
      "params.PUSH_EXTRA_ARGS"
      "params.SKIP_PUSH"
      "params.TLS_VERIFY"
      "params.VERBOSE"
      "workspaces.source.bound"
      "workspaces.source.path"
      "workspaces.dockerconfig.bound"
      "workspaces.dockerconfig.path"
      "workspaces.rhel-entitlement.bound"
      "workspaces.rhel-entitlement.path"
      "results.IMAGE_URL.path"
      "results.IMAGE_DIGEST.path"
}}
{{- include "environment" ( list $variables ) | nindent 6 }}

  steps:
    - name: build
      image: {{ .Values.images.buildah }}
      workingDir: $(workspaces.source.path)
      args:
        - $(params.BUILD_ARGS[*])
      script: |
{{- include "load_scripts" ( list . ( list "buildah-" ) ( list "/scripts/buildah-bud.sh" ) ) | nindent 8 }}
      securityContext:
        capabilities:
          add: ["SETFCAP"]
      volumeMounts:
        - name: scripts-dir
          mountPath: /scripts

  volumes:
    - name: scripts-dir
      emptyDir: {}
{{- end -}}
{{- end -}} 