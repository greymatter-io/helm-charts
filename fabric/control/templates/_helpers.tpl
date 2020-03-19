{{/*
Define the namespaces Control will monitor
*/}}
{{- define "control.namespaces" -}}
{{- if $.Values.global.control_additional_namespaces }}
{{- printf "%s,%s"  $.Release.Namespace $.Values.global.control_additional_namespaces -}}
{{- else }}
{{- printf "%s" $.Release.Namespace }}
{{- end }}
{{- end -}}