{{- $s2iBuilderImage := .Values.s2iBuilders.go -}}
{{- $s2iLanguage := "go" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
