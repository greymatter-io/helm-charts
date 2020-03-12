{{- define "edge_spire_volume_mounts" }}
- name: spire-agent-socket
  mountPath: /run/spire/sockets
  readOnly: true
{{- end }}

{{- define "edge_volume_certs_mount" }}
- name: edge-egress
  mountPath: {{ .Values.edge.certificates.egress.mountPoint }}
  readOnly: true
{{- end }}
