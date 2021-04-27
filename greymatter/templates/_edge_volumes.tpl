{{- define "edge_egress_volumes" }}
- name: edge-egress
  secret:
    {{- if .Values.global.global_certs.enabled }}
    # Has three certs but even though egress only uses ca
    secretName: global-certs
    {{- else }}
    secretName: {{ .Values.edge.egress.secret.secret_name }}
    {{- end }}
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
