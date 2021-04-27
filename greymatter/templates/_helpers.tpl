{{/*
Define the namespaces Control will monitor
*/}}
{{- define "control.namespaces" -}}
{{- if $.Values.global.control.additional_namespaces }}
{{- printf "%s,%s"  $.Release.Namespace $.Values.global.control.additional_namespaces -}}
{{- else }}
{{- printf "%s" $.Release.Namespace }}
{{- end }}
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

{{/*
Handles replicas for releases.
Takes in global.release.X and .Values.<service>.replicas
Presidence is globals > service level > default to 1
*/}}
{{- define "replicas" -}}
  {{- $top := index . "top" -}}
  {{- $svc_rep := index . "service_values" -}}
  {{- if and $top.Values.global.release.production $top.Values.global.release.default_replicas }}
  {{- print $top.Values.global.release.default_replicas  }}
  {{- else if  $svc_rep }}
  {{- print $svc_rep }}
  {{- else }}
  {{- print 1 }}
  {{- end -}}
{{- end -}}


{{- define "sidecar_volume_certs_mount" }}
- name: sidecar-certs
  mountPath: {{ .Values.sidecar.secret.mount_point }}
  readOnly: true
{{- end }}

{{- define "sidecar_certs_volumes" }}
- name: sidecar-certs
  secret:
    secretName: {{ .Values.sidecar.secret.secret_name }}
{{- end }}

{{/*
Grey Matter Volume Mounts
*/}}
{{- define "greymatter.volumeMounts" -}}
  {{- if .Values.global.spire.enabled }}
  {{- include "spire_volume_mount" . | indent 8 }}
  {{- else if .Values.sidecar.secret.enabled }}
  {{- include "sidecar_volume_certs_mount" . | indent 8 }}
  {{- end }}
{{- end -}}

{{/*
Print the Grey Matter Label
*/}}
{{- define "greymatter.control.label" -}}
  {{- $context := index . "context" -}}
  {{- $label := index . "name" -}}
    {{- printf "%s: %s" $context.Values.global.control.cluster_label $label -}}
{{- end -}}

{{- define "greymatter.labels" -}}
  {{- $context := index . "context" -}}
  {{- $label := index . "name" -}}
  {{- include "greymatter.control.label" (dict "name" $label "context" $context) }}
{{ printf "deployment: %s" $label }}
{{- end -}}

{{/*
Define a common set of ImagePullSecrets
{{ include "greymatter.imagePullSecrets" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "global" .Values.global) }}
*/}}
{{- define "greymatter.imagePullSecrets" -}}
  {{- $pullSecrets := list -}}

  {{- if .global }}
    {{- range .global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- range .images -}}
    {{- range .imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
    {{- range $pullSecrets }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Define the Grey Matter Sidecar Image
*/}}
{{- define "greymatter.sidecar.image" -}}
{{ printf "%s" $.Values.sidecar.image }}
{{- end -}}

{{/*
Define a image pull policy for all images
{{ include "greymatter.imagePullPolicy" ( dict "root" .Values.path.to.image "global" $) }}
*/}}
{{- define "greymatter.imagePullPolicy" -}}
{{- $imagePullPolicy := .root.imagePullPolicy -}}
{{- if .global }}
  {{- if .global.imagePullPolicy }}
    {{- $imagePullPolicy = .global.imagePullPolicy }}
  {{- end }}
{{- end -}}
{{ printf "%s" $imagePullPolicy }}
{{- end -}}

