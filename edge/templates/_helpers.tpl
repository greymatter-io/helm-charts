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
compensates for known issue in openshift 3.11 that marks status as a required field
https://github.com/openshift/origin/issues/24060
*/}}
{{- define "openshift.route.fix" -}}
status:
  ingress:
    - host: ""
{{- end -}}