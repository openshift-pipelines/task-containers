{{- /*

  Contains the common elements found on all s2i tasks, uses the first parameter to share the global
  context and the second to inform the desired s2i builder image.

*/ -}}

{{- define "spec_s2i" -}}
  {{- $s2iBuilderImage := index . 1 -}}
  {{- with index . 0 -}}
workspaces:
  - name: source
    optional: false
    description: |
      Application source code, the build context for S2I workflow.
  - name: dockerconfig
    optional: true
    description: >-
        An optional workspace that allows providing a .docker/config.json file for Buildah to access the container registry.
        The file should be placed at the root of the Workspace with name config.json.
        
params:
  - name: IMAGE
    type: string
    description: |
      Fully qualified container image name to be built by s2i.
  - name: VERSION
    description: The tag of go imagestream for go version
    default: latest
    type: string
  - name: IMAGE_SCRIPTS_URL
    type: string
    default: image:///usr/libexec/s2i         
    description: |
      Specify a URL containing the default assemble and run scripts for the builder image
  - name: ENV_VARS
    type: array
    default: []
    description: |
      Array containing string of Environment Variables as "KEY=VALUE"

{{- include "params_buildah_common" . | nindent 2 }}
{{- include "params_common" . | nindent 2 }}

results:
{{- include "results_buildah" . | nindent 2 }}

stepTemplate:
  env:
{{- $variables := list
      "params.IMAGE"
      "params.VERSION"
      "params.IMAGE_SCRIPTS_URL"
      "params.CONTEXT"
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
      "results.IMAGE_URL.path"
      "results.IMAGE_DIGEST.path"
}}
{{- include "environment" ( list $variables ) | nindent 4 }}

steps:
{{- include "load_scripts" ( list . "buildah-" "s2i-" ) | nindent 2 }}

  - name: s2i-generate
    image: {{ .Values.images.s2i }}
    workingDir: $(workspaces.source.path)
    env:
      - name: S2I_BUILDER_IMAGE
        value: "{{ $s2iBuilderImage }}:$(params.VERSION)"
    command:
      - /scripts/s2i-generate.sh
    args:
      - "$(params.ENV_VARS[*])"
    securityContext:
      capabilities:
        add: ["SETFCAP"]
    volumeMounts:
      - name: scripts-dir
        mountPath: /scripts
      - name: s2i-generate-dir
        mountPath: /s2i-generate

  - name: s2i-build
    image: {{ .Values.images.buildah }}
    workingDir: /s2i-generate
    command:
      - /scripts/s2i-build.sh
    securityContext:
      capabilities:
        add: ["SETFCAP"]
    volumeMounts:
      - name: scripts-dir
        mountPath: /scripts
      - name: s2i-generate-dir
        mountPath: /s2i-generate

volumes:
  - name: scripts-dir
    emptyDir: {}
  - name: s2i-generate-dir
    emptyDir: {}
  {{- end -}}
{{- end -}}
