{{/*
Handles replicas for releases.
Takes in global.release.X and .Values.<service>.replicas
Presidence is globals > service level > default to 1
*/}}
{{- define "replicas" -}}
  {{- $top := index . "top" -}}
  {{- $svc_rep := index . "service_values" -}}
  {{- if and $top.Values.global.release.production $top.Values.global.release.default_replicas -}}
  {{ print $top.Values.global.release.default_replicas }}
  {{- else if  $svc_rep -}}
  {{ print $svc_rep }}
  {{ else -}}
  {{ print 1 }}
  {{- end }}
{{- end }}