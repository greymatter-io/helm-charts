{{/*
Builds out the SPIRE mounts when configured
{{ include "greymatter.common.sidecar.spire.mounts" . }}
*/}}
{{- define "greymatter.common.sidecar.spire.mounts" -}}
- name: spire-socket
  mountPath: /run/spire/socket
  readOnly: false
{{- end -}}

{{/*
Builds out the SPIRE volume when configured
{{ include "greymatter.common.sidecar.spire.volume" . }}
*/}}
{{- define "greymatter.common.sidecar.spire.volume" -}}
- name: spire-socket
  hostPath:
    path: /run/spire/socket
    type: DirectoryOrCreate
{{- end -}}


{{/*
Builds the Grey Matter Sidecar Certificate Volume when SPIRE is disabled
{{ include "greymatter.common.sidecar.certificates.volume" (dict "sidecar" .Values.path.to.sidecar.configs) }}
*/}}
{{- define "greymatter.common.sidecar.certificates.volume" -}}
- name: sidecar-certs
  secret:
    secretName: {{ .sidecar.secret.secretName }}
{{- end -}}


{{/*
Builds the Grey Matter Sidecar Certificate Volume Mount when SPIRE is disabled
{{ include "greymatter.common.sidecar.certificates.mounts" (dict "sidecar" .Values.path.to.sidecar.configs) }}
*/}}
{{- define "greymatter.common.sidecar.certificates.mounts" -}}
- name: sidecar-certs
  mountPath: {{ .sidecar.secret.mount_point }}
  readOnly: true
{{- end -}}

{{/*
Builds out the Consul Agent Container when Consul is enabled
{{ include "greymatter.common.consul.agent" (dict "consul" .Values.path.to.global.consul "service" .Values.path.to.service) }}
*/}}
{{- define "greymatter.common.consul.agent" -}}
  {{- if .consul.enabled -}}
- name: consul
  image: {{ .consul.image }}
  imagePullPolicy: IfNotPresent
  env:
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
  - name: NAME
    value: {{ .service.name }}
  command: ["/bin/sh", "-ec"]
  args:
    - "echo '{
        \"Service\": {
        \"name\":\"$(NAME)\",
        \"address\": \"$(POD_IP)\",
        \"port\": {{ .consul.edge_port }},
        \"tags\": [\"gm-cluster\"],
        \"meta\": {
            \"metrics\": \"8081\"
            },
        \"check\": [
            {
                \"name\": \"$(NAME) health check\",
                \"tcp\": \"$(POD_IP):{{ .consul.edge_port }}\",
                \"interval\": \"10s\"
            }
            ]
        }}' > /consul/config/$(NAME)-consul.json \
        && exec /bin/consul agent \
        -data-dir=/consul/data \
        -advertise=\"$(POD_IP)\" \
        -retry-join=\"{{ .consul.host }}\" \
        -config-dir=/consul/config"
  volumeMounts:
  - name: data-consul
    mountPath: /consul/data
  - name: config-consul
    mountPath: /consul/config
  {{- end -}}
{{- end -}}


{{/*
Buils out the Grey Matter Sidecar Volumes when Console is enabled
{{ include "greymatter.common.consul.volume" . }}
*/}}
{{- define "greymatter.common.consul.volume" -}}
- name: data-consul
  emptyDir: {}
- name: config-consul
  emptyDir: {}
{{- end -}}

{{/*
Builds the Grey Matter Sidecar Volumes Mounts
{{ include "greymatter.common.sidecar.certificates.mounts" (dict "sidecar" .Values.path.to.sidecar.configs "global" .Values.path.to.global) }}
*/}}
{{- define "greymatter.common.sidecar.mounts" }}
  {{- if .global.spire.enabled -}}
    {{ include "greymatter.common.sidecar.spire.mounts" . }}
  {{- else -}}
    {{ include "greymatter.common.sidecar.certificates.mounts" (dict "sidecar" .sidecar )}}
  {{- end -}}
{{- end }}

{{/*
Builds the Grey Matter Sidecar Volumes
{{ include "greymatter.common.sidecar.certificates.volume" (dict "sidecar" .Values.path.to.sidecar.configs "global" .Values.path.to.global) }}
*/}}
{{- define "greymatter.common.sidecar.volumes" }}
  {{- if .global.spire.enabled -}}
    {{ include "greymatter.common.sidecar.spire.volume" . }}
  {{- else -}}
    {{ include "greymatter.common.sidecar.certificates.volume" (dict "sidecar" .sidecar )}}
  {{- end }}
  {{ if .global.consul.enabled }}
{{ include "greymatter.common.consul.volume" . }}
  {{- end -}}
{{- end }}

{{/*
Buils the environment variables supplied by
{{- include "greymatter.common.sidecar.envvars" (dict "sidecar" .context.Values.sidecar "value" .service.sidecar.envvars "global" .global "context" .context) -}}
*/}}
{{- define "greymatter.common.sidecar.envvars" -}}
  {{- include "common.tplvalues.render" (dict "value" .value "context" .context) | nindent 2 }}
  {{- include "common.tplvalues.render" (dict "value" .sidecar.envvars "context" .context) | nindent 2 }}
  {{- if .global.spire.enabled -}}
    {{- include "common.tplvalues.render" (dict "value" .global.spire.envvars "context" .context) | nindent 2 }}
  {{- end -}}
{{- end -}}



{{/*
Builds out the configs for a Grey Matter Sidecar
{{ include "greymatter.sidecar" (dict "sidecar" .Values.path.to.sidecar "service" .Values.path.to.service "global" .Values.global "context" $) }}
*/}}
{{- define "greymatter.common.sidecar" -}}
- name: greymatter-sidecar
  image: {{ .sidecar.image | quote }}
  imagePullPolicy: {{ include "greymatter.common.imagePullPolicy" (dict "service" .service "global" .global ) }}
  env:
  {{- include "greymatter.common.sidecar.envvars" (dict "sidecar" .sidecar "value" .service.sidecar.envvars "global" .global "context" .context) | indent 2 }}

  {{- if .sidecar.resources }}
  resources: {{ toYaml .sidecar.resources | nindent 4 }}
  {{- end }}
  ports:
  - containerPort: {{ .sidecar.port }}
    name: proxy
    protocol: TCP
  - containerPort: {{ .sidecar.metrics_port }}
    name: metrics
    protocol: TCP
  volumeMounts: {{ include "greymatter.common.sidecar.mounts" (dict "sidecar" .sidecar "global" .global) | nindent 2 }}
{{- end -}}