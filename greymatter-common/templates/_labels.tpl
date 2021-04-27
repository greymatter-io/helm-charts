{{/* vim: set filetype=mustache: */}}
{{/*
Print the Grey Matter Label
*/}}
{{- define "greymatter.common.labels.control" -}}
  {{- $context := index . "context" -}}
  {{- $label := index . "name" -}}
    {{- printf "%s: %s" $context.Values.global.control.cluster_label $label -}}
{{- end -}}

{{- define "greymatter.common.labels" -}}
  {{- $context := index . "context" -}}
  {{- $label := index . "name" -}}
  {{- include "greymatter.common.labels.control" (dict "name" $label "context" $context) }}
{{ printf "deployment: %s" $label }}
{{- end -}}