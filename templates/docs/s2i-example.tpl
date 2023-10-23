{{- define "s2i_example" -}}
  {{- $s2iLanguage := index . 1 -}}
  {{- with index . 0 -}}
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  labels:
    name: pipeline-s2i-{{ $s2iLanguage }}
  name: pipeline-s2i-{{ $s2iLanguage }}
spec:
  workspaces:
    - name: source
      optional: false

  params:
    - name: URL
      type: string
    - name: REVISION
      type: string
    - name: IMAGE
      type: string
    - name: IMAGE_SCRIPTS_URL
      type: string
    - name: TLS_VERIFY
      type: string
    - name: VERBOSE
      type: string
    - name: ENV_VARS
      type: array

  tasks:
    - name: git
      taskRef:
        name: git
      workspaces:
        - name: output
          workspace: source
      params:
        - name: URL
          value: "source-code-url"
        - name: REVISION
          value: "master"
        - name: SUBMODULES
          value: "false"
        - name: VERBOSE
          value: "true"
    - name: s2i-{{ $s2iLanguage }}
      taskRef:
        name: s2i-{{ $s2iLanguage }}
      runAfter:
        - git
      workspaces:
        - name: source
          workspace: source
      params:
        - name: IMAGE
          value: "registry-url"
        - name: TLS_VERIFY
          value: "false"
        - name: VERBOSE
          value: "true"
{{- if eq $s2iLanguage "dotnet" }}
{{ "" | indent 8 }}
        - name: ENV_VARS
          value:
            - "DOTNET_STARTUP_PROJECT=CleanArchitecture.Api/CleanArchitecture.Api.csproj"
{{- end }}
{{- if eq $s2iLanguage "java" }}
{{ "" | indent 8 }}
        - name: ENV_VARS
          value:
            - "MAVEN_CLEAR_REPO=false"
        - name: IMAGE_SCRIPTS_URL
          value: "image:///usr/local/s2i"
{{- end }}
  {{- end -}}
{{- end -}}