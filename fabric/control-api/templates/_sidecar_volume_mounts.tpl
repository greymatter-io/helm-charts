{{- define "sidecar_volume_certs_mount" }}
- name: sidecar-certs
  mountPath: {{ .Values.sidecar.secret.mount_point }}
  readOnly: true
{{- end }}