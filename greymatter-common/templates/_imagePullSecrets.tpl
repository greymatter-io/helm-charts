{{/*
Define a image pull secrets for all images
{{ include "greymatter.common.imagePullSecrets" ( dict "service" .Values.path.to.service "global" .Values.path.to.global) }}
*/}}
{{- define "greymatter.common.imagePullSecrets" -}}
  {{- $pullSecrets := list -}}

  {{- if .global }}
    {{- range .global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- range .service.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets . -}}
  {{- end -}}


  {{- if (not (empty $pullSecrets)) }}
    {{- range $pullSecrets }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}