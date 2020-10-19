package test

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
	"testing"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"

	"github.com/gruntwork-io/terratest/modules/helm"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
)

// Setup the args. For this test, we will set the following input values:
var options = &helm.Options{
	ValuesFiles: []string{"../global.yaml"},
	SetValues:   map[string]string{"global.environment": "kubernetes"},
}

// Helm Dep up does not require any extra options
var emptyOptions = &helm.Options{}

var noWaiterOptions = &helm.Options{
	ValuesFiles: []string{"../global.yaml"},
	SetValues:   map[string]string{"global.environment": "kubernetes", "global.waiter.service_account.create": "false"},
}

// Helm Chart Release Names
var spireReleaseName = fmt.Sprintf("spire-%s", strings.ToLower(random.UniqueId()))
var fabricReleaseName = fmt.Sprintf("fabric-%s", strings.ToLower(random.UniqueId()))
var edgeReleaseName = fmt.Sprintf("edge-%s", strings.ToLower(random.UniqueId()))
var senseReleaseName = fmt.Sprintf("sense-%s", strings.ToLower(random.UniqueId()))

// Expected Pod Count for each Grey Matter Helm Chart
var spirePodCount = 6
var fabricPodCount = 5
var edgePodCount = 1
var sensePodCount = 5

// Expected Catalog service count for Grey Matter
var expectedCatalogCount = 6

// TestSpire tests that the spire pods are all running as expected
func TestSpire(t *testing.T) {
	// Setup the kubectl config and context. Here we choose to use the defaults, which is:
	// - HOME/.kube/config for the kubectl config file
	// - Current context of the kubectl config file
	// We also specify that we are working in the default namespace (required to get the Pod)
	// Spire runs in the spire namespace so we need to set the namespace context here
	kubectlOptions := k8s.NewKubectlOptions("", "", "spire")

	// Install spire
	spireChartPath := "../spire"

	if _, err := helm.RunHelmCommandAndGetOutputE(t, options, "dependency", "update", spireChartPath); err != nil {
		require.NoError(t, err)
	}

	helm.Install(t, options, spireChartPath, spireReleaseName)

	labelSelector := metav1.LabelSelector{MatchLabels: map[string]string{"greymatter": "spire"}}
	filters := metav1.ListOptions{
		LabelSelector: labels.Set(labelSelector.MatchLabels).String(),
		Limit:         100,
	}

	podName := "server-0"
	retries := 15
	sleep := 5 * time.Second
	k8s.WaitUntilPodAvailable(t, kubectlOptions, podName, retries, sleep)

	verifyPods(t, kubectlOptions, spirePodCount, filters)
}

// TestFabric tests that the fabric pods are all running as expected
func TestFabric(t *testing.T) {

	// Reset the kubectlOptions to the default Namespace
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

	//Install Fabric

	// Path to the helm chart we will test
	fabricChartPath := "../fabric"
	// We generate a unique release name so that we can refer to after deployment.
	// By doing so, we can schedule the delete call here so that at the end of the test, we run
	// `helm delete RELEASE_NAME` to clean up any resources that were created.

	// Update the dependencies for this chart
	if _, err := helm.RunHelmCommandAndGetOutputE(t, options, "dependency", "update", fabricChartPath); err != nil {
		require.NoError(t, err)
	}

	// Deploy the chart using `helm install`. Note that we use the version without `E`, since we want to assert the
	// install succeeds without any errors.
	helm.Install(t, options, fabricChartPath, fabricReleaseName)

	labelSelector := metav1.LabelSelector{MatchLabels: map[string]string{"greymatter": "fabric"}}
	filters := metav1.ListOptions{
		LabelSelector: labels.Set(labelSelector.MatchLabels).String(),
		Limit:         100,
	}

	verifyPods(t, kubectlOptions, fabricPodCount, filters)

}

// TestEdge tests that the edge pod is running as expected
func TestEdge(t *testing.T) {

	// Reset the kubectlOptions to the default Namespace
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

	// Install Edge

	edgeChartPath := "../edge"
	helm.Install(t, options, edgeChartPath, edgeReleaseName)

	labelSelector := metav1.LabelSelector{MatchLabels: map[string]string{"greymatter": "edge"}}
	filters := metav1.ListOptions{
		LabelSelector: labels.Set(labelSelector.MatchLabels).String(),
		Limit:         100,
	}

	verifyPods(t, kubectlOptions, edgePodCount, filters)
}

// TestSense tests that the sense pods are all running as expected
func TestSense(t *testing.T) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

	// Install Sense
	senseChartPath := "../sense"
	if _, err := helm.RunHelmCommandAndGetOutputE(t, options, "dependency", "update", senseChartPath); err != nil {
		require.NoError(t, err)
	}

	helm.Install(t, noWaiterOptions, senseChartPath, senseReleaseName)

	// numberPods :=

	labelSelector := metav1.LabelSelector{MatchLabels: map[string]string{"greymatter": "sense"}}
	filters := metav1.ListOptions{
		LabelSelector: labels.Set(labelSelector.MatchLabels).String(),
		Limit:         100,
	}

	verifyPods(t, kubectlOptions, sensePodCount, filters)
}

// TestEdgePatch tests that we can supply a patch to the edge service. This is necessary so we
// can communicate with the edge service in k3d
func TestEdgePatch(t *testing.T) {

	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

	// Wait for the service to be available before we try to patch it
	retries := 15
	sleep := 10 * time.Second
	k8s.WaitUntilServiceAvailable(t, kubectlOptions, "edge", retries, sleep)

	// Patch the edge svc so we can access the catalog
	k8s.RunKubectl(t, kubectlOptions, "patch", "svc", "edge", "-p", "{\"spec\": {\"type\": \"LoadBalancer\"}}")

	// Wait for the service to be available after the patch before we move on
	k8s.WaitUntilServiceAvailable(t, kubectlOptions, "edge", retries, sleep)
}

// TestCatalog tests that catalog is correctly configured in the mesh
func TestCatalog(t *testing.T) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")
	verifyCatalog(t, kubectlOptions)
}

// TestTearDown tests removing Grey Matter via helm
func TestTearDown(t *testing.T) {
	helm.Delete(t, options, spireReleaseName, true)
	helm.Delete(t, options, fabricReleaseName, true)
	helm.Delete(t, options, edgeReleaseName, true)
	helm.Delete(t, noWaiterOptions, senseReleaseName, true)
}

// verifyFabricPod will open a tunnel to the Pod and hit the endpoint to verify the nginx welcome page is shown.
func verifyFabricPod(t *testing.T, kubectlOptions *k8s.KubectlOptions, podName string) {
	// Wait for the pod to come up. It takes some time for the Pod to start, so retry a few times.
	retries := 15
	sleep := 5 * time.Second
	k8s.WaitUntilPodAvailable(t, kubectlOptions, podName, retries, sleep)

	// We will first open a tunnel to the pod, making sure to close it at the end of the test.
	tunnel := k8s.NewTunnel(kubectlOptions, k8s.ResourceTypePod, podName, 0, 8001)
	defer tunnel.Close()
	tunnel.ForwardPort(t)

	// ... and now that we have the tunnel, we will verify that we get back a 200 OK with the nginx welcome page.
	// It takes some time for the Pod to start, so retry a few times.
	endpoint := fmt.Sprintf("http://%s", tunnel.Endpoint())
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		endpoint,
		nil,
		retries,
		sleep,
		func(statusCode int, title string) bool {
			return statusCode == 200 && strings.Contains(title, "Envoy Admin")
		},
	)
}

// verifyPods will verify that expected pods are running
func verifyPods(t *testing.T, kubectlOptions *k8s.KubectlOptions, expectedPodCount int, filters metav1.ListOptions) {

	// Wait for the pod to come up. It takes some time for the Pod to start, so retry a few times.
	retries := 15
	sleep := 5 * time.Second

	k8s.WaitUntilNumPodsCreated(t, kubectlOptions, filters, expectedPodCount, retries, sleep)

	pods := k8s.ListPods(t, kubectlOptions, filters)

	if len(pods) != expectedPodCount {
		podError := k8s.DesiredNumberOfPodsNotCreated{
			Filter:       filters,
			DesiredCount: expectedPodCount,
		}
		log.Fatal(podError)
	}

	for _, pod := range pods {
		fmt.Println("Pod: ", pod.Name)
	}
}

func verifyCatalog(t *testing.T, kubectlOptions *k8s.KubectlOptions) {

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	certPem, err := ioutil.ReadFile("../certs/quickstart.crt")
	if err != nil {
		log.Fatal(err)
	}
	keyPem, err := ioutil.ReadFile("../certs/quickstart.key")
	if err != nil {
		log.Fatal(err)
	}

	cert, err := tls.X509KeyPair(certPem, keyPem)
	if err != nil {
		log.Fatal(err)
	}

	tlsConfig := tls.Config{
		Certificates:       []tls.Certificate{cert},
		InsecureSkipVerify: true,
	}

	// The Edge node requires a bit of time to get configured and we've seen issues where it will die before it' ready. This adds a sleep for 30 seconds to give it time to serve requests
	time.Sleep(30 * time.Second)

	// Define the path to the catalog service
	catalogEndpoint := "https://localhost:30000/services/catalog/latest/summary"

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		catalogEndpoint,
		&tlsConfig,
		30,
		10*time.Second,
		func(statusCode int, body string) bool {
			// fmt.Println("Catalog Summary:", body)

			var data map[string]interface{}
			json.Unmarshal([]byte(body), &data)
			metadata, _ := data["metadata"].(map[string]interface{})

			foundCatalogCount := metadata["clusterCount"]

			return foundCatalogCount == float64(expectedCatalogCount)
		},
	)
}
