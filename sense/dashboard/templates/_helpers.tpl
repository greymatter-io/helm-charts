{{/*
Create the namespace list for Prometheus to monitor
*/}}
{{- define "greymatter.dashboard.prometheus_namespaces" -}}
{{- $namespaces := dict "namespaces" (list) -}}
{{- $noop := printf "%s" $.Release.Namespace | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- if $.Values.global.control.additional_namespaces -}}
{{- range $ns, $e := splitList "," $.Values.global.control.additional_namespaces -}}
{{- $noop := printf "%s" $e | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- end -}}
{{- end -}}
{{- range $a, $b := $namespaces.namespaces -}}
{{- $c := $b | quote -}}
{{- $d := cat "-" $c -}}
{{- println $d -}}
{{- end -}}
{{- end -}}

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