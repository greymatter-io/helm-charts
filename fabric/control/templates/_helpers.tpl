{{/*
Define the namespaces Control will monitor
*/}}
{{- define "control.namespaces" -}}
{{- if $.Values.control.additional_namespaces_to_control }}
{{- printf "%s,%s"  $.Release.Namespace $.Values.control.additional_namespaces_to_control -}}
{{- else }}
{{- printf "%s" $.Release.Namespace }}
{{- end }}
{{- end -}}