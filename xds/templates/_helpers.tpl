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

{{- define "proxy" -}}
        image: {{ tpl .Values.sidecar.image $ }}
        imagePullPolicy: {{ .Values.sidecar.imagePullPolicy }}
        ports:
        - name: grpc
            containerPort: 8443
        - name: metrics
            containerPort: 8080
        env:
        - name: INGRESS_USE_TLS
            value: "true"
        - name: INGRESS_CA_CERT_PATH
            value: "/etc/proxy/tls/sidecar/ca.crt"
        - name: INGRESS_CERT_PATH
            value: "/etc/proxy/tls/sidecar/server.crt"
        - name: INGRESS_KEY_PATH
            value: "/etc/proxy/tls/sidecar/server.key"
        - name: METRICS_PORT
            value: "8080"
        - name: PORT
            value: "8443"
        - name: SERVICE_HOST
            value: "127.0.0.1"
        - name: SERVICE_PORT
            value: {{ .Values.global.xds.port | quote }}
        - name: ZK_ADDRS
            value: {{ template "greymatter.exhibitor.address" . }}
        - name: ZK_ANNOUNCE_PATH
            value: "/services/xds/{{ .Values.xds.version }}"
        volumeMounts:
        - name: sidecar
            mountPath: /etc/proxy/tls/sidecar
        - name: edge
            mountPath: /etc/proxy/tls/edge
{{- end -}}