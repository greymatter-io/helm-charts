{{/*
To use this add '{{ .Files.Get (include "cert" (dict "path" $fromfile "file" "ca.crt") ) '
to fet a file from $filepath .  in this case the file is named ca.crt
*/}}
{{- define "cert" -}}
{{- $path := index . "path" -}}
{{- $file := index . "file" -}}
{{- $output := printf "%s/%s" $path $file -}}
{{- print $output -}}
{{- end -}}

{{/*
put a cert ontop of a key.  for use in mongo where it expects this
*/}}
{{- define "combocertkey" }}
{{- $crt := index . "crtsrc" }}
{{- $key := index . "keysrc" }}
{{- printf "%s\n%s" $crt $key}}
{{- end }}

{{- define "secrets.domain" -}}
  {{- if .Values.global.route_url_name }}
{{- printf "%s.%s" .Values.global.route_url_name .Values.global.domain -}}
  {{- else }}
{{- printf "%s" .Values.global.domain -}}
  {{- end }}
{{- end -}}

{{- define "secrets.userDn" -}}
{{- printf "greymatter.user" -}}
{{- end -}}
