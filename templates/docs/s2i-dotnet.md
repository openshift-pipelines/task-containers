{{- $s2iBuilderImage := .Values.s2iBuilders.dotnet -}}
{{- $s2iLanguage := "dotnet" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
