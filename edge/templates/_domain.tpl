{{- define "greymatter.domain" }}
    {{- if (contains ":" .Values.global.domain) -}}
        {{ (split ":" .Values.global.domain)._0 }}
    {{- else }}
        {{- if .Values.global.route_url_name }}
            {{- if .Values.global.remove_namespace_from_url  }}
    {{- .Values.global.route_url_name }}.{{ .Values.global.domain }}
            {{- else }}
    {{- .Values.global.route_url_name }}.{{ .Release.Namespace }}.{{ .Values.global.domain }}
            {{- end }}
        {{- else }}
    {{- .Values.global.domain -}}
        {{- end }}
    {{- end }}
{{- end }}