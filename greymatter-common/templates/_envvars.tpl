{{/*
Buils the environment variables supplied by
*/}}
{{- define "greymatter.common.envvars" -}}
  {{- include "common.tplvalues.render" (dict "value" .Values.sidecar.envvars "context" .) | nindent 8 }}
  {{- if .Values.global.spire.enabled -}}
    {{- include "common.tplvalues.render" (dict "value" .Values.global.spire.envvars "context" .) | nindent 8 }}
  {{- end -}}
{{- end -}}