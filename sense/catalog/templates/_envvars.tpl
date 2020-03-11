{{- define "envvars" }}
  {{- $e := index . "envvar" }}
  {{- $t := index . "top" }}
  {{- range $name, $envvar := $e }}
    {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- if eq $envvar.type "secret" }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $envvar.secret }}
      key: {{ $envvar.key }}
    {{- else if eq $envvar.type "value" }}
- name: {{ $envName }}
  value: {{ tpl $envvar.value $t | quote }}
      {{- end }}
  {{- end }}
{{- end }}
{{- /*  envvars loops through the global sidecar envvars and generates Kubernetes container env keys for both regular values and secrets from the local sidecar values and from the global values as a backup.
We use indentation in the template for readability, but the template returns the output without indents, leaving it up to the user
Most users should use the `indent` or `nindent` functions to automatically indent the proper amount. */}}
{{- define "greymatter.envvars" }}
  {{- $top := . }}
  {{- if .Values.global.sidecar }}
    {{- range $name, $envvar := .Values.global.sidecar.envvars }}
          {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
          {{- $l := "" }}
          {{- if $top.Values.sidecar.envvars }}
            {{- $l = index $top.Values.sidecar.envvars $name }}
          {{- end}}
          {{- $e := $l | default $envvar }}
          {{- $args := dict "name" $envName "value" $e "top" $top }}
          {{- include "envvars" $args }}
    {{- end }}
  {{- else }}
    {{- range $name, $envvar := .Values.sidecar.envvars }}
          {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
          {{- $args := dict "name" $envName "value" $envvar "top" $top }}
          {{- include "envvars" $args }}
    {{- end }}
  {{- end }}
{{- end }}
