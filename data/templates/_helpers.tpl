{{/*
Define the exhibitor host.
*/}}
{{- define "greymatter.exhibitor.address" -}}
{{- $zk := dict "servers" (list) -}}
{{- range $i, $e := until (atoi (printf "%d" (int64 .Values.global.exhibitor.replicas))) -}} 
{{- $noop := printf "%s%d.%s.%s.%s"  "exhibitor-" . "exhibitor" $.Release.Namespace "svc.cluster.local:2181" | append $zk.servers | set $zk "servers" -}}
{{- end -}}
{{- join "," $zk.servers | quote -}}
{{- end -}}

{{/*
Define the mongo host.
*/}}
{{- define "greymatter.mongo.address" -}}
{{- $mongo := dict "servers" (list) -}}
{{- range $i, $e := until (atoi (printf "%d" (int64 .Values.mongo.replicas))) -}} 
{{- $noop := printf "%s%s%d.%s.%s.%s"  $.Values.mongo.name "-" . $.Values.mongo.name $.Release.Namespace "svc.cluster.local:27017" | append $mongo.servers | set $mongo "servers" -}}
{{- end -}}
{{- join "," $mongo.servers | quote -}}
{{- end -}}
