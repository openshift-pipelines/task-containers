{{- $s2iBuilderImage := .Values.s2iBuilders.nodejs -}}
{{- $s2iLanguage := "nodejs" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
