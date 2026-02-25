package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	imageName       = "timjdfletcher/ssh-audit"
	imageTag        = "tmp"
	sshAuditVersion = "3.3.0"
)

func TestDockerBuild(t *testing.T) {
	buildOptions := &docker.BuildOptions{
		Tags: []string{imageName + ":" + imageTag},
	}

	docker.Build(t, "../", buildOptions)
}

func TestSSHAuditVersion(t *testing.T) {
	t.Parallel()

	opts := &docker.RunOptions{
		Command: []string{"--help"},
	}

	output := docker.Run(t, imageName+":"+imageTag, opts)

	assert.Contains(t, output, "v"+sshAuditVersion, "Version should match expected")
	assert.Contains(t, output, "usage:", "Help output should contain usage")
}

func TestSSHAuditBinaryExists(t *testing.T) {
	t.Parallel()

	opts := &docker.RunOptions{
		Command:    []string{"-c", "test -f /usr/local/bin/ssh-audit"},
		Entrypoint: "sh",
	}

	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestHardenedSSHDPassesAudit(t *testing.T) {
	t.Parallel()

	opts := &docker.Options{
		WorkingDir: "../",
	}

	docker.RunDockerCompose(t, opts, "up", "-d", "--wait")
	defer docker.RunDockerCompose(t, opts, "down", "--remove-orphans")

	execOpts := &docker.Options{
		WorkingDir: "../",
	}

	output, err := docker.RunDockerComposeE(t, execOpts, "exec", "-T", "ssh-audit", "ssh-audit", "-p", "2222", "test-sshd")

	require.NoError(t, err, "Hardened sshd should pass audit with exit code 0")
	assert.Contains(t, output, "(kex)", "Output should contain key exchange info")
	assert.NotContains(t, output, "[fail]", "Output should not contain failures")
}

func TestWeakSSHDFailsAudit(t *testing.T) {
	t.Parallel()

	opts := &docker.Options{
		WorkingDir: "../",
	}

	docker.RunDockerCompose(t, opts, "up", "-d", "--wait")
	defer docker.RunDockerCompose(t, opts, "down", "--remove-orphans")

	execOpts := &docker.Options{
		WorkingDir: "../",
	}

	output, err := docker.RunDockerComposeE(t, execOpts, "exec", "-T", "ssh-audit", "ssh-audit", "-p", "2222", "weak-sshd")

	require.Error(t, err, "Weak sshd should fail audit")
	assert.Contains(t, output, "[fail]", "Output should contain failures for weak config")
}

func TestJSONOutput(t *testing.T) {
	t.Parallel()

	opts := &docker.Options{
		WorkingDir: "../",
	}

	docker.RunDockerCompose(t, opts, "up", "-d", "--wait")
	defer docker.RunDockerCompose(t, opts, "down", "--remove-orphans")

	execOpts := &docker.Options{
		WorkingDir: "../",
	}

	output, _ := docker.RunDockerComposeE(t, execOpts, "exec", "-T", "ssh-audit", "ssh-audit", "-p", "2222", "--json", "test-sshd")

	assert.True(t, strings.Contains(output, `"banner":`), "JSON output should contain banner field")
}
