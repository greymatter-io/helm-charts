{{- define "sidecar_certs_volumes" }}
- name: sidecar-certs
  secret:
    secretName: {{ .Values.sidecar.secret.secret_name }}
{{- end }}
