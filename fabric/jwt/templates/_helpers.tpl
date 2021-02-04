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
Handles replicas for releases.
Takes in global.release.X and .Values.<service>.replicas
Presidence is globals > service level > default to 1
*/}}
{{- define "replicas" -}}
  {{- $top := index . "top" -}}
  {{- $svc_rep := index . "service_values" -}}
  {{- if and $top.Values.global.release.production $top.Values.global.release.default_replicas -}}
  {{ print $top.Values.global.release.default_replicas }}
  {{- else if  $svc_rep -}}
  {{ print $svc_rep }}
  {{ else -}}
  {{ print 1 }}
  {{- end }}
{{- end }}