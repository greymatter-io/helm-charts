{{- define "edge_spire_volumes" }}
- name: spire-agent-socket
  hostPath:
    path: /run/spire/sockets
    type: Directory
{{- end }}

{{- define "edge_egress_volumes" }}
- name: edge-egress
  secret:
    secretName: {{ .Values.edge.egress.secret.secret_name }}
{{- end }}

{{- define "edge_ingress_volumes" }}
- name: edge-ingress
  secret:
    secretName: {{ .Values.edge.ingress.secret.secret_name }}
{{- end }}
