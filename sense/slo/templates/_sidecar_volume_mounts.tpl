{{- define "sidecar_volume_mounts" }}
- name: spire-agent-socket
  mountPath: /run/spire/sockets
  readOnly: true
{{- end }}

{{- define "sidecar_volume_certs_mount" }}
- name: sidecar-certs
  mountPath: {{ .Values.sidecar.secret.mountPoint }}
  readOnly: true
{{- end }}