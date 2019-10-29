{{/*
Define the namespaces Control will monitor
*/}}
{{- define "control.namespaces" -}}
{{- if $.Values.global.control.additionalNamespacesToControl }}
{{- printf "%s,%s"  $.Release.Namespace $.Values.global.control.additionalNamespacesToControl -}}
{{- else }}
{{- printf "%s" $.Release.Namespace }}
{{- end }}
{{- end -}}