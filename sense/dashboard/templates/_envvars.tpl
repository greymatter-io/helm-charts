{{- define "envvars" }}
  {{- $e := index . "envvar" }}
  {{- $t := index . "top" }}
  {{- range $name, $envvar := $e }}
    {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- if eq $envvar.type "secret" }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl $envvar.secret $t }}
      key: {{ $envvar.key }}
      {{- else if eq $envvar.type "value" }}
- name: {{ $envName }}
  value: {{ tpl $envvar.value $t | quote }}
      {{- end }}
  {{- end }}
{{- end }}


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
- name: {{ $envName }}
  value: {{ tpl $e.value $top | quote }} 
            {{- end }}
{{- end }}

{{- /* merged envvars for dashboard sidecar*/}}
{{- define "sidecar.envvars-dashboard" }}
 {{- $top := . }}
  {{- if and .Values.global.sidecar.envvars $top.Values.sidecar_dashboard.envvars }}
    {{- $allvars := merge $top.Values.sidecar_dashboard.envvars .Values.global.sidecar.envvars }}
    {{- range $name, $envvar := $allvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- else if .Values.global.sidecar.envvars }}
    {{- range $name, $envvar := .Values.global.sidecar.envvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- else if $top.Values.sidecar_dashboard.envvars }}
    {{- range $name, $envvar := $top.Values.sidecar_dashboard.envvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /* merged envvars for prometheus sidecar*/}}
{{- define "sidecar.envvars-prometheus" }}
 {{- $top := . }}
  {{- if and .Values.global.sidecar.envvars $top.Values.sidecar_prometheus.envvars }}
    {{- $allvars := merge $top.Values.sidecar_prometheus.envvars .Values.global.sidecar.envvars }}
    {{- range $name, $envvar := $allvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- else if .Values.global.sidecar.envvars }}
    {{- range $name, $envvar := .Values.global.sidecar.envvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- else if $top.Values.sidecar_prometheus.envvars }}
    {{- range $name, $envvar := $top.Values.sidecar_prometheus.envvars }}
      {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
      {{- $args := dict "name" $envName "value" $envvar "top" $top }}
      {{- include "envvar" $args }}
    {{- end }}
  {{- end }}
{{- end }}