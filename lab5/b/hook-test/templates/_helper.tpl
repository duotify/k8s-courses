{{/*
Create labels for deployment
*/}}
{{- define "deployment.labels" -}}
app: {{ .Release.Name }}-{{ .Chart.Name }}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}

{{/*
Create labels for pre-install
*/}}
{{- define "pre.labels" -}}
app: {{ .Release.Name }}-{{ .Chart.Name }}-pre
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}

{{/*
Create labels for test
*/}}
{{- define "test.labels" -}}
app: {{ .Release.Name }}-{{ .Chart.Name }}-test
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
{{- end -}}

