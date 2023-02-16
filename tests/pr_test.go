// Tests in this file are run in the PR pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-observability-agents"
const terraformDirOther = "examples/basic"

var ignoreUpdates = []string{
	"module.observability_agents.helm_release.logdna_agent[0]",
	"module.observability_agents.helm_release.sysdig_agent[0]",
	"module.observability_agents.helm_release.logdna_agent_activity_tracker[0]",
	"module.observability_agents.helm_release.logdna_sts_agent[0]",
}

var sharedInfoSvc *cloudinfo.CloudInfoService

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {
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
	})

	return options
}

func TestRunBasicAgents(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "basic-obs-agents", terraformDirOther)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgrade(t *testing.T) {
	t.Parallel()

	// TODO: Remove this line after the first merge to primary branch is complete to enable upgrade test
	t.Skip("Skipping upgrade test until initial code is in primary branch")

	options := setupOptions(t, "observ-agents-upg", terraformDirOther)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
