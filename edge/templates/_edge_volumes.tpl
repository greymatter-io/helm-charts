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

{{- define "spire_volumes" }}
- name: spire-socket
  hostPath:
    path: /run/spire/socket
    type: DirectoryOrCreate
{{- end }}
