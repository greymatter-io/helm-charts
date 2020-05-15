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

{{- define "spire_volume_mount" }}
- name: spire-socket
  mountPath: /run/spire/socket
  readOnly: false
{{- end }}