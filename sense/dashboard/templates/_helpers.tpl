{{/*
Create the namespace list for Prometheus to monitor
*/}}
{{- define "greymatter.dashboard.prometheus_namespaces" -}}
{{- $namespaces := dict "namespaces" (list) -}}
{{- $noop := printf "%s" $.Release.Namespace | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- if $.Values.global.control_additional_namespaces -}}
{{- range $ns, $e := splitList "," $.Values.global.control_additional_namespaces -}}
{{- $noop := printf "%s" $e | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- end -}}
{{- end -}}
{{- range $a, $b := $namespaces.namespaces -}}
{{- $c := $b | quote -}}
{{- $d := cat "-" $c -}}
{{- println $d -}}
{{- end -}}
{{- end -}}