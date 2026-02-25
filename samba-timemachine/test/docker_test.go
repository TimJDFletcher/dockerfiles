package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	imageName     = "timjdfletcher/samba-timemachine"
	imageTag      = "tmp"
	containerName = "samba-timemachine"
	volumeName    = "samba-timemachine_backups"
)

// Test environment variables
var testEnv = map[string]string{
	"PUID":      "1234",
	"PGID":      "4321",
	"USER":      "testuser",
	"PASS":      "Password123",
	"LOG_LEVEL": "4",
}

// === BUILD-TIME TESTS ===

func TestDockerBuild(t *testing.T) {
	buildOptions := &docker.BuildOptions{
		Tags: []string{imageName + ":" + imageTag},
	}
	docker.Build(t, "../", buildOptions)
}

func TestEntrypointExists(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "test -f /entrypoint && test -x /entrypoint"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestTemplatesExist(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "test -f /templates/smb.conf.tmpl && test -f /templates/README.md"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestConfigNotPresentBeforeEntrypoint(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "test ! -f /etc/samba/smb.conf"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestSambaPackageInstalled(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "dpkg -l samba | grep -q '^ii'"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestCurlPurged(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "! dpkg -l curl 2>/dev/null | grep -q '^ii'"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestEnvsubstWorks(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "echo '$TEST_VAR' | TEST_VAR=success envsubst | grep -q success"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

func TestVfsFruitModuleExists(t *testing.T) {
	t.Parallel()
	opts := &docker.RunOptions{
		Command:    []string{"-c", "find /usr/lib -name fruit.so | grep -q fruit.so"},
		Entrypoint: "sh",
	}
	docker.Run(t, imageName+":"+imageTag, opts)
}

// === INTEGRATION TESTS ===

func TestIntegrationSuite(t *testing.T) {
	// Setup: create volume and test file
	cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Phase 1: FORCE_PERMISSIONS_RESET=false
	t.Run("Phase1_DefaultPermissions", func(t *testing.T) {
		env := copyEnv(testEnv)
		env["FORCE_PERMISSIONS_RESET"] = "false"

		startContainer(t, env)
		defer stopContainer(t)

		waitForHealthy(t, 60*time.Second)

		t.Run("LiveTests", func(t *testing.T) {
			testSmbdRunning(t)
			testConfigRendered(t, env)
			testUserCreated(t, env)
			testSmbIntegration(t, env)
		})

		t.Run("PermissionsNotReset", func(t *testing.T) {
			testFileOwnership(t, "/backups/permission-test-file", "root", "root")
		})
	})

	// Phase 2: FORCE_PERMISSIONS_RESET=true
	t.Run("Phase2_ForcedPermissionsReset", func(t *testing.T) {
		env := copyEnv(testEnv)
		env["FORCE_PERMISSIONS_RESET"] = "true"

		startContainer(t, env)
		defer stopContainer(t)

		waitForHealthy(t, 60*time.Second)

		t.Run("PermissionsReset", func(t *testing.T) {
			testFileOwnership(t, "/backups/permission-test-file", env["USER"], env["USER"])
		})
	})
}

// === HELPER FUNCTIONS ===

func setupTestEnvironment(t *testing.T) func() {
	t.Helper()

	// Cleanup any previous runs
	shell.RunCommand(t, shell.Command{
		Command: "docker",
		Args:    []string{"compose", "down", "--volumes", "--remove-orphans"},
		WorkingDir: "../",
	})

	// Create volume
	shell.RunCommand(t, shell.Command{
		Command: "docker",
		Args:    []string{"volume", "create", volumeName},
	})

	// Create test file with root ownership
	shell.RunCommand(t, shell.Command{
		Command: "docker",
		Args: []string{
			"run", "--rm",
			"-v", volumeName + ":/backups",
			"debian:stable-slim",
			"bash", "-c", "touch /backups/permission-test-file && chown root:root /backups/permission-test-file",
		},
	})

	return func() {
		shell.RunCommand(t, shell.Command{
			Command: "docker",
			Args:    []string{"compose", "down", "--volumes", "--remove-orphans"},
			WorkingDir: "../",
		})
		shell.RunCommand(t, shell.Command{
			Command: "docker",
			Args:    []string{"volume", "rm", volumeName},
		})
	}
}

func startContainer(t *testing.T, env map[string]string) {
	t.Helper()

	args := []string{"compose", "up", "-d", "--remove-orphans"}
	cmd := shell.Command{
		Command:    "docker",
		Args:       args,
		WorkingDir: "../",
		Env:        env,
	}
	shell.RunCommand(t, cmd)
}

func stopContainer(t *testing.T) {
	t.Helper()
	shell.RunCommand(t, shell.Command{
		Command:    "docker",
		Args:       []string{"compose", "down", "--remove-orphans"},
		WorkingDir: "../",
	})
}

func waitForHealthy(t *testing.T, timeout time.Duration) {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		output := shell.RunCommandAndGetOutput(t, shell.Command{
			Command:    "docker",
			Args:       []string{"compose", "ps", "--format", "json"},
			WorkingDir: "../",
		})
		if strings.Contains(output, `"Health":"healthy"`) {
			return
		}
		time.Sleep(2 * time.Second)
	}
	t.Fatal("Timeout waiting for container to become healthy")
}

func execInContainer(t *testing.T, command string) string {
	t.Helper()
	output := shell.RunCommandAndGetOutput(t, shell.Command{
		Command:    "docker",
		Args:       []string{"compose", "exec", "-T", containerName, "sh", "-c", command},
		WorkingDir: "../",
	})
	return output
}

func copyEnv(env map[string]string) map[string]string {
	newEnv := make(map[string]string)
	for k, v := range env {
		newEnv[k] = v
	}
	return newEnv
}

// === TEST ASSERTIONS ===

func testSmbdRunning(t *testing.T) {
	t.Helper()
	output := execInContainer(t, "pgrep smbd")
	assert.NotEmpty(t, output, "smbd process should be running")
}

func testConfigRendered(t *testing.T, env map[string]string) {
	t.Helper()

	output := execInContainer(t, "cat /etc/samba/smb.conf")
	assert.Contains(t, output, fmt.Sprintf("log level               = %s", env["LOG_LEVEL"]),
		"smb.conf should contain correct log level")
	assert.Contains(t, output, "path                    = /backups",
		"smb.conf should contain correct path")

	// testparm validation
	output = execInContainer(t, "/usr/bin/testparm --suppress-prompt --verbose 2>&1")
	assert.Contains(t, output, "Loaded services file OK", "testparm should validate config")
	assert.Contains(t, output, "fruit:time machine = yes", "Time Machine should be enabled")
}

func testUserCreated(t *testing.T, env map[string]string) {
	t.Helper()

	// Check user exists with correct UID
	output := execInContainer(t, fmt.Sprintf("id -u %s", env["USER"]))
	assert.Contains(t, output, env["PUID"], "User should have correct UID")

	// Check group exists with correct GID
	output = execInContainer(t, fmt.Sprintf("id -g %s", env["USER"]))
	assert.Contains(t, output, env["PGID"], "User should have correct GID")
}

func testSmbIntegration(t *testing.T, env map[string]string) {
	t.Helper()

	cmd := fmt.Sprintf(
		"/usr/bin/smbclient //127.0.0.1/Data -U %s%%%s -I 127.0.0.1 -p 10445 -c 'mkdir terratest_dir; ls; rmdir terratest_dir'",
		env["USER"], env["PASS"],
	)
	output := execInContainer(t, cmd)

	assert.Contains(t, output, "terratest_dir", "SMB should create test directory")
	assert.Contains(t, output, ".com.apple.TimeMachine.supported", "TimeMachine marker should exist")
}

func testFileOwnership(t *testing.T, path, expectedOwner, expectedGroup string) {
	t.Helper()

	output := execInContainer(t, fmt.Sprintf("stat -c '%%U:%%G' %s", path))
	expected := fmt.Sprintf("%s:%s", expectedOwner, expectedGroup)
	require.Contains(t, output, expected,
		fmt.Sprintf("File %s should be owned by %s", path, expected))
}
