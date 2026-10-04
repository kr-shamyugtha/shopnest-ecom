{{/*
Standard labels for a ShopNest component. Call with the component name:
  {{- include "shopnest.labels" (dict "component" "backend") | nindent 4 }}
*/}}
{{- define "shopnest.labels" -}}
app.kubernetes.io/name: shopnest-{{ .component }}
app.kubernetes.io/part-of: shopnest
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Label that Deployment selectors, Services, PDBs, anti-affinity and NetworkPolicies
use to find a component's pods. Deployment selectors are immutable, so changing
this on a live release means recreating the Deployment.
*/}}
{{- define "shopnest.selectorLabels" -}}
app: shopnest-{{ .component }}
{{- end }}
