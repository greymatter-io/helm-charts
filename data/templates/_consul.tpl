{{/* Generate consul container */}}
{{- define "consul.agent" }}
- name: consul
  image: consul:1.5.0
  imagePullPolicy: IfNotPresent
  env:
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
  - name: NAME
    value: {{ .ServiceName }}
  command: ["/bin/sh", "-ec"]
  args: 
    - "echo '{
        \"Service\": {
        \"name\":\"$(NAME)\",
        \"address\": \"$(POD_IP)\",
        \"port\": {{ .Values.global.edge_port }},
        \"tags\": [\"gm-cluster\"],
        \"meta\": {
            \"metrics\": \"8081\"
            },
        \"check\": [
            {
                \"name\": \"$(NAME) health check\",
                \"tcp\": \"$(POD_IP):{{ .Values.global.edge_port }}\",
                \"interval\": \"10s\"
            }
            ]
        }}' > /consul/config/$(NAME)-consul.json \
        && exec /bin/consul agent \
        -data-dir=/consul/data \
        -advertise=\"$(POD_IP)\" \
        -retry-join=\"{{ .Values.global.consul.host }}\" \
        -config-dir=/consul/config"
  volumeMounts:
  - name: data-consul
    mountPath: /consul/data
  - name: config-consul
    mountPath: /consul/config
{{- end }}
