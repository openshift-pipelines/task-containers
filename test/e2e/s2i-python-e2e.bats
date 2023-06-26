#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline
readonly E2E_PARAM_PATH_CONTEXT="${E2E_PARAM_PATH_CONTEXT:-.}"
readonly E2E_PYTHON_PVC_NAME="${E2E_PYTHON_PVC_NAME:-}"
readonly E2E_S2I_IMAGE="${E2E_S2I_IMAGE:-}"



# Spinning up a PipelineRun using the S2I Go Task to build and push a container image
@test "[e2e] pipeline-run using s2i-python task" {
  # Asserting required configuration is informed
  [ -n "${E2E_PARAM_PATH_CONTEXT}" ]
  [ -n "${E2E_PYTHON_PVC_NAME}" ]
  [ -n "${E2E_S2I_IMAGE}" ]
  [ -n "${E2E_S2I_TLS_VERIFY}" ] 


  # Cleaning up existing resources before starting a new pipelinerun
  run kubectl delete pipelinerun --all
  assert_success

  # E2E PipelineRun
  run tkn pipeline start task-s2i-python \
    --param="PATH_CONTEXT=${E2E_PARAM_PATH_CONTEXT}" \
    --param="TLS_VERIFY=${E2E_S2I_TLS_VERIFY}" \
    --param="IMAGE=${E2E_S2I_IMAGE}" \
    --param="VERBOSE=true" \
    --workspace="name=source,claimName=${E2E_PYTHON_PVC_NAME},subPath=source" \
    --filename=test/e2e/resources/pipeline-s2i-python.yaml \
    --showlog >&3
  assert_success

  # Waiting a few seconds before asserting results
  sleep 15

  #
  # Asserting PipelineRun Status
  #


  # Asserting Status
  readonly tmpl_file="${BASE_DIR}/go-template.tpl"

  cat >${tmpl_file} <<EOS
{{- range .status.conditions -}}
  {{- if and (eq .type "Succeeded") (eq .status "True") }}
    {{ .message }}
  {{- end }}
{{- end -}}
EOS

  # Using template to select the required information and asserting the task has succeeded
  run tkn pipelinerun describe --output=go-template-file --template=${tmpl_file}
  assert_success


  # Asserting Results
  cat >${tmpl_file} <<EOS
{{- range .status.taskResults -}}
    {{ printf "%s=%s\n" .name .value }}
{{- end -}}
EOS

  # Using a template to render the result attributes on a multi-line key-value pair output
  run tkn pipelinerun describe --output=go-template-file --template=${tmpl_file}
  assert_success
  
}

# Cleaning up the resources
teardown() {
    rm -f tmpl_file
}