{{- define "generic.envvars" }}
  {{- $e := index . "envvars" }}
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