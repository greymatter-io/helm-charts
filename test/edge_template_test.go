package test

import (
	"fmt"
	"testing"

	appsv1 "k8s.io/api/apps/v1"

	"github.com/gruntwork-io/terratest/modules/helm"
)

func TestPodTemplateRendersContainerImage(t *testing.T) {
	// Path to the helm chart we will test
	helmChartPath := "../edge"

	// Setup the args. For this test, we will set the following input values:
	// - image=nginx:1.15.8
	options := &helm.Options{
		SetValues: map[string]string{"edge.image": "docker.greymatter.io/release/gm-proxy:1.4.5"},
	}

	// Run RenderTemplate to render the template and capture the output.
	output := helm.RenderTemplate(t, options, helmChartPath, "deployment", []string{"templates/edge.yaml"})

	// Now we use kubernetes/client-go library to render the template output into the Pod struct. This will
	// ensure the Pod resource is rendered correctly.
	var deployment appsv1.Deployment
	helm.UnmarshalK8SYaml(t, output, &deployment)

	// Finally, we verify the pod spec is set to the expected container image value
	expectedContainerImage := "docker.greymatter.io/release/gm-proxy:1.4.5"
	podContainers := deployment.Spec.Template.Spec.Containers
	if podContainers[0].Image != expectedContainerImage {
		t.Fatalf("Rendered container image (%s) is not expected (%s)", podContainers[0].Image, expectedContainerImage)
	}

	// Let's verify that the correct GM Control Label is on the pod
	expectedPodLabel := "greymatter.io/control"
	podLabels := deployment.Spec.Template.Labels
	label := podLabels[expectedPodLabel]
	fmt.Printf("%v", label)
	if label != "" {
		t.Fatalf("Rendered container labels are missing the expected label (%s)", expectedPodLabel)
	}
}
