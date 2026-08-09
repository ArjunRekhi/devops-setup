{{- define "podinfo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride }}
{{- end }}

{{/* Kept separate from labels: a Deployment's selector is immutable, so the
     version and chart labels must not be folded in. */}}
{{- define "podinfo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "podinfo-app.name" . }}
{{- end }}

{{- define "podinfo-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{ include "podinfo-app.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "podinfo-app.serviceAccountName" -}}
{{- default (include "podinfo-app.name" .) .Values.serviceAccount.name }}
{{- end }}

{{- define "podinfo-app.secretName" -}}
{{- default (printf "%s-secret" (include "podinfo-app.name" .)) .Values.secrets.existingSecret }}
{{- end }}
