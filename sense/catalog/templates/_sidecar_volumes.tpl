{{- define "sidecar_certs_volumes" }}
- name: sidecar-certs
  secret:
    secretName: {{ .Values.sidecar.secret.secret_name }}
{{- end }}

{{- define "spire_volumes" }}
- name: spire-socket
  hostPath:
    path: /run/spire/socket
    type: DirectoryOrCreate
{{- end }}