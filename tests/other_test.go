// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const terraformDirLogsAgentIKS = "examples/obs-agent-iks"
const terraformDirLogsAgentROKS = "examples/obs-agent-ocp"

func TestRunAgentClassicKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-iks", terraformDirLogsAgentIKS)
	options.TerraformVars["is_vpc_cluster"] = false
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-iks", terraformDirLogsAgentIKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcOcp(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "obs-agent-roks", terraformDirLogsAgentROKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcOcpUpgrade(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "log-agent-upg", terraformDirLogsAgentROKS)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
