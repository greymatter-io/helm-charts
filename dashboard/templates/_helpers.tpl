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
Create the namespace list for Prometheus to monitor
*/}}
{{- define "greymatter.dashboard.prometheus_namespaces" -}}
{{- $namespaces := dict "namespaces" (list) -}}
{{- $noop := printf "%s" $.Release.Namespace | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- if $.Values.global.control.additionalNamespacesToControl -}}
{{- range $ns, $e := splitList "," $.Values.global.control.additionalNamespacesToControl -}}
{{- $noop := printf "%s" $e | append $namespaces.namespaces | set $namespaces "namespaces" -}}
{{- end -}}
{{- end -}}
{{- range $a, $b := $namespaces.namespaces -}}
{{- $c := $b | quote -}}
{{- $d := cat "-" $c -}}
{{- println $d -}}
{{- end -}}
{{- end -}}