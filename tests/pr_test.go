// Tests in this file are run in the PR pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// const resourceGroup = "geretain-test-observability-agents"
const resourceGroup = "default"
const terraformDirOther = "examples/basic"

var ignoreUpdates = []string{
	"module.observability_agents.helm_release.sysdig_agent[0]",
	"module.observability_agents.helm_release.logdna_agent[0]",
	"module.observability_agents.helm_release.logdna_agent_activity_tracker[0]",
	"module.observability_agents.helm_release.log_analysis_agent[0]",
	"module.observability_agents.helm_release.cloud_monitoring_agent[0]",
	"ibm_is_subnet.testacc_subnet",
	"module.observability_agents.helm_release.log_analysis_agent_activity_tracker[0]",
}

var extTerraformVars = map[string]interface{}{}

var sharedInfoSvc *cloudinfo.CloudInfoService

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string, terraformVars map[string]interface{}) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{
			List: ignoreUpdates,
		},
		CloudInfoService:              sharedInfoSvc,
		ExcludeActivityTrackerRegions: true,
		TerraformVars:                 terraformVars,
	})

	return options
}

func TestRunBasicAgents(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "basic-obs-agents", terraformDirOther, extTerraformVars)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgrade(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "observ-agents-upg", terraformDirOther, extTerraformVars)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestRunBasicAgentsKubernetes(t *testing.T) {
	t.Parallel()

	var extTerraformVarsK8s = map[string]interface{}{}
	extTerraformVarsK8s["is_openshift"] = false

	options := setupOptions(t, "basic-obs-agents-k8s", terraformDirOther, extTerraformVarsK8s)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
