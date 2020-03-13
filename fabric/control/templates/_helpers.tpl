{{/*
Define the namespaces Control will monitor
*/}}
{{- define "control.namespaces" -}}
{{- if $.Values.control.additionalNamespacesToControl }}
{{- printf "%s,%s"  $.Release.Namespace $.Values.control.additionalNamespacesToControl -}}
{{- else }}
{{- printf "%s" $.Release.Namespace }}
{{- end }}
{{- end -}}