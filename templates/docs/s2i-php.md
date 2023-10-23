{{- $s2iBuilderImage := .Values.s2iBuilders.php -}}
{{- $s2iLanguage := "php" -}}
{{ include "s2i_doc" ( list . $s2iLanguage $s2iBuilderImage ) }}
