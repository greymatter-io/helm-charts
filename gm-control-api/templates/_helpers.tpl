{{- define "greymatter.domain" }}
    {{- if .Values.global.remove_namespace_from_url  }}
{{- .Values.global.route_url_name }}.{{ .Values.global.domain }}
    {{- else }}
{{- .Values.global.route_url_name }}.{{ .Release.Namespace }}.{{ .Values.global.domain }}
    {{- end }}
{{- end }}