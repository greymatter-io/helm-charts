{{- define "envvars" }}
  {{- $e := index . "envvar" }}
  {{- $t := index . "top" }}
  {{- range $name, $envvar := $e }}
    {{- $envName := $name | upper | replace "." "_" | replace "-" "_" }}
    {{- /* They may be times when default environment variables don't need to be set.  This allows an operator to set the type to null which tells the function to skip that environment variable */}}
    {{- if not (eq $envvar.type "null") }}
      {{- if eq $envvar.type "secret" }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl $envvar.secret $t }}
      key: {{ tpl $envvar.key $t }}
      {{- else if eq $envvar.type "value" }}
- name: {{ $envName }}
  value: {{ tpl $envvar.value $t | quote }}
      {{- end }}
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
