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
const terraformDirLogsAgentIKS = "examples/obs-agent-iks"
const terraformDirLogsAgentROKS = "examples/obs-agent-ocp"

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
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.observability_agents.helm_release.logs_agent[0]",
			},
		},
		CloudInfoService: sharedInfoSvc,
	})

	return options
}

func TestRunLogsAgentKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-iks", terraformDirLogsAgentIKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunLogsAgentOCP(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-roks", terraformDirLogsAgentROKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunLogsAgentUpgrade(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "log-agent-upg", terraformDirLogsAgentROKS)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
