{{- define "edge_spire_volume_mounts" }}
- name: spire-agent-socket
  mountPath: /run/spire/sockets
  readOnly: true
{{- end }}

{{- define "edge_egress_certs_mount" }}
- name: edge-egress
  mountPath: {{ .Values.edge.egress.secret.mount_point }}
  readOnly: true
{{- end }}

{{- define "edge_ingress_certs_mount" }}
- name: edge-ingress
  mountPath: {{ .Values.edge.ingress.secret.mount_point }}
  readOnly: true
{{- end }}
