{{- $s2iBuilderImage := .Values.s2iBuilders.java -}}
{{- $s2iLanguage := "java" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
