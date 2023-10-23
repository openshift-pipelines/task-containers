{{- $s2iBuilderImage := .Values.s2iBuilders.ruby -}}
{{- $s2iLanguage := "ruby" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
