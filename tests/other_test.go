// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRunBasicAgents(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "basic-obs-agents", terraformDirOther, extTerraformVars)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunBasicAgentsKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "basic-obs-agents-k8s", terraformDirOther, extTerraformVars)
	options.TerraformVars["is_openshift"] = false

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunBasicAgentsClassic(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "basic-obs-agents-classic", terraformDirOther, extTerraformVars)
	options.TerraformVars["is_vpc_cluster"] = false

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
