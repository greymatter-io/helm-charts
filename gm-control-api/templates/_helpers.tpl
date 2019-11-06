{{- define "greymatter.domain" }}
    {{- if .Values.global.remove_namespace_from_url  }}
{{- .Values.global.route_url_name }}.{{ .Values.global.domain }}
    {{- else }}
{{- .Values.global.route_url_name }}.{{ .Release.Namespace }}.{{ .Values.global.domain }}
    {{- end }}
{{- end }}

{{- define "tlsconfig" }}
    {{- if .Values.global.control_api_tls  }}
    - name: GM_CONTROL_API_USE_TLS
      value: {{ .Values.global.control_api_tls | quote }}
    - name: GM_CONTROL_API_CA_CERT_PATH
      value: {{ .Values.gmControlApi.ssl.mountPoint}}/ca.crt
    - name: GM_CONTROL_API_SERVER_CERT_PATH
      value: {{ .Values.gmControlApi.ssl.mountPoint}}/server.crt
    - name: GM_CONTROL_API_SERVER_KEY_PATH
      value: {{ .Values.gmControlApi.ssl.mountPoint}}/server.key
    {{- end }}
{{- end }}