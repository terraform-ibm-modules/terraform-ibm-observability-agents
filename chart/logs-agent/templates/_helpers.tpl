{{- /* Template Helpers */}}

{{- /* logs.defaultMetadata
Creates additional entries for the filter-add-meta-data.conf filter
By default the output plugin sets the applicationName and subsystemName for Cloud Logs
to:
- applicationName = kubernetes container name
- subsystemName =   kubernetes namespace
This can be overridden to static values by setting the
- defaultMetadata.applicationName
- defaultMetadata.subsystemName
Note, that this will only change the default values.  If an application provides either
applicationName or subsystemName in the message that will take precedence over this setting.
*/}}
{{- define "logs.defaultMetadata" }}
  {{- if .Values.defaultMetadata }}
    {{- if .Values.defaultMetadata.applicationName }}
        Add applicationName {{ .Values.defaultMetadata.applicationName }}
    {{- end -}}
    {{- if .Values.defaultMetadata.subsystemName }}
        Add subsystemName {{ .Values.defaultMetadata.subsystemName }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* logs.daemonsetResources
Return the resources section for the daemonset based on the overrides provided by the user.
If the resources values are provided, it's assumed that all limits and requests values are provided.
*/}}
{{- define "logs.daemonsetResources" }}
  {{- if .Values.resources -}}
{{- toYaml .Values.resources | nindent 12}}
  {{- else }}
            limits:
              cpu: 500m
              ephemeral-storage: 10Gi
              memory: 3Gi
            requests:
              cpu: 100m
              ephemeral-storage: 2Gi
              memory: 1Gi
  {{- end -}}
{{ end -}}
