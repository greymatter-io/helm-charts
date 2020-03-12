{{- define "sidecar_volumes" }}
- name: spire-agent-socket
  hostPath:
    path: /run/spire/sockets
    type: Directory
{{- end }}

{{- define "sidecar_certs_volumes" }}
- name: sidecar-certs
  secret:
    secretName: {{ .Values.sidecar.secret.secret_name }}
{{- end }}
