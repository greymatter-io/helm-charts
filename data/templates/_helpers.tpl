{{/*
Define the exhibitor host.
*/}}
{{- define "greymatter.exhibitor.address" -}}
{{- $zk := dict "servers" (list) -}}
{{- range $i, $e := until (atoi (printf "%d" (int64 .Values.global.exhibitor.replicas))) -}} 
{{- $noop := printf "%s%d.%s.%s.%s"  "exhibitor-" . "exhibitor" $.Release.Namespace "svc:2181" | append $zk.servers | set $zk "servers" -}}
{{- end -}}
{{- join "," $zk.servers | quote -}}
{{- end -}}

{{/*
Define the mongo host.
*/}}
{{- define "greymatter.mongo.address" -}}
{{- $mongo := dict "servers" (list) -}}
{{- range $i, $e := until (atoi (printf "%d" (int64 .Values.mongo.replicas))) -}} 
{{- $noop := printf "%s%s%d.%s.%s.%s"  $.Values.mongo.name "-" . $.Values.mongo.name $.Release.Namespace "svc:27017" | append $mongo.servers | set $mongo "servers" -}}
{{- end -}}
{{- join "," $mongo.servers | quote -}}
{{- end -}}

{{/*
Define the sidecar certs volume.  Required here to support a standalone Grey Matter Data deployment
*/}}
{{- define "sidecar_certs_volumes" }}
- name: sidecar-certs
  secret:
    secretName: {{ .Values.sidecar.certs.secret_name }}
{{- end }}

{{/*
Define where to mount the sidecar certs.  Required here to support a standalone Grey Matter Data deployment
*/}}
{{- define "sidecar_volume_certs_mount" }}
- name: sidecar-certs
  mountPath: /etc/proxy/tls/sidecar/
  readOnly: true
{{- end }}