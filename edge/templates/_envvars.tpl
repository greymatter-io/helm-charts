{{/* envvar take a dictionary of name, value, and top as arguments, and generates a single environment variable from it. */}}
{{/* Top must be the scope of the top of a named template or any scope which includes the default values, namely .Template (since we use the `tpl` function in this template, .Template.BasePath is required for some reason) */}}
{{- define "envvar" }}
    {{- $envName := index . "name" }}
    {{- $e := index . "value" }}
    {{- $top := index . "top" }}
        {{- if eq $e.type "secret" }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $e.secret }}
      key: {{ $e.key }}
          {{- else if eq $e.type "value" }}
          {{- /* The following removes any undefined values. At this stage, it means both the local and global values are undefined, so its best to just get rid of it */}}
            {{- if (tpl $e.value $top) ne "" }}
- name: {{ $envName }}
  value: {{ tpl $e.value $top | quote }} 
            {{- end }}
          {{- end }}
{{- end }}

{{- /*  envvars loops through the global sidecar envvars and generates Kubernetes container env keys for both regular values and secrets from the local sidecar values and from the global values as a backup.
We use indentation in the template for readability, but the template returns the output without indents, leaving it up to the user
Most users should use the `indent` or `nindent` functions to automatically indent the proper amount. */}}
{{- define "edge.envvars" }}
  {{- $top := . }}
  {{- if .Values.edge.envvars }}
    {{- range $name, $envvar := .Values.edge.envvars }}
          {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
          {{- $l := "" }}
          {{- if $top.Values.edge.envvars }}
            {{- $l = index $top.Values.edge.envvars $name }}
          {{- end}}
          {{- $e := $l | default $envvar }}
          {{- $args := dict "name" $envName "value" $e "top" $top }}
          {{- include "envvar" $args }}
    {{- end }}
  {{- else }}
    {{- range $name, $envvar := .Values.sidecar.envvars }}
          {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
          {{- $args := dict "name" $envName "value" $envvar "top" $top }}
          {{- include "envvar" $args }}
    {{- end }}
  {{- end }}
{{- end }}
