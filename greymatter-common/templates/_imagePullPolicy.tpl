{{/*
Define a image pull policy for all images
{{ include "greymatter.common.imagePullPolicy" ( dict "service" .Values.path.to.service "global" .Values.path.to.global) }}
*/}}
{{- define "greymatter.common.imagePullPolicy" -}}
{{- $imagePullPolicy := .service.imagePullPolicy | default "IfNotPresent" -}}
{{- if .global }}
  {{- if .global.imagePullPolicy }}
    {{- $imagePullPolicy = .global.imagePullPolicy }}
  {{- end }}
{{- end -}}
{{ printf "%s" $imagePullPolicy }}
{{- end -}}