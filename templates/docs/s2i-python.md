{{- $s2iBuilderImage := .Values.s2iBuilders.python -}}
{{- $s2iLanguage := "python" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
