{{- $s2iBuilderImage := .Values.s2iBuilders.perl -}}
{{- $s2iLanguage := "perl" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
