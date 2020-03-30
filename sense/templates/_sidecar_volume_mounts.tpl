{{- define "sidecar_volume_certs_mount" }}
- name: sidecar-certs
  mountPath: {{ .Values.sidecar.secret.mount_point }}
  readOnly: true
{{- end }}

{{- define "spire_volume_mount" }}
- name: spire-socket
  mountPath: /run/spire/socket
  readOnly: false
{{- end }}