{{- define "edge_spire_volumes" }}
- name: spire-agent-socket
  hostPath:
    path: /run/spire/sockets
    type: Directory
{{- end }}

{{- define "edge_certs_volumes" }}
- name: edge-egress
  secret:
    secretName: {{ .Values.edge.certificates.egress.name }}
{{- end }}