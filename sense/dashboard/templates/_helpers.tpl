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
define role name
*/}}
{{- define "prometheus.role.name" -}}
{{ printf "%s-%s" .Values.prometheus.service_account.name "role" }}
{{- end -}}

{{/*
define primary namespace rolebinding name
*/}}
{{- define "prometheus.rolebinding.name" -}}
{{ printf "%s-%s" .Values.prometheus.service_account.name "rolebinding" }}
{{- end -}}

{{/*
define additional namespace rolebinding name
*/}}
{{- define "prometheus.rolebinding.additional.name" -}}
{{ printf "%s-%s-%s" .Values.prometheus.service_account.name "rolebinding" "$e" }}
{{- end -}}