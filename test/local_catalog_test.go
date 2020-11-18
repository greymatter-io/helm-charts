package test

import (
	"crypto/tls"
	"encoding/json"
	"io/ioutil"
	"log"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

func TestCatalog(t *testing.T) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

	// k8s.RunKubectl(t, kubectlOptions, "patch", "svc", "edge", "-p", "{\"spec\": {\"type\": \"LoadBalancer\"}}")

	verifyCatalog(t, kubectlOptions)
}

func verifyCatalog(t *testing.T, kubectlOptions *k8s.KubectlOptions) {

	// Define the edge service name, and we'll connect to it when ready
	// serviceName := "edge"
	// // servicePort := 10808

	// k8s.WaitUntilServiceAvailable(t, kubectlOptions, serviceName, 10, 1*time.Second)

	// service := k8s.GetService(t, kubectlOptions, serviceName)
	// endpoint := k8s.GetServiceEndpoint(t, kubectlOptions, service, servicePort)

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

	// Define the path to the catalog service
	// catalogEndpoint := fmt.Sprintf("https://%s/services/catalog/latest/clusters", endpoint)
	catalogEndpoint := "https://localhost:30000/services/catalog/latest/summary"

	expected := 6
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		catalogEndpoint,
		&tlsConfig,
		0,
		1*time.Second,
		func(statusCode int, body string) bool {
			// fmt.Println("Catalog Summary:", body)

			var data map[string]interface{}
			json.Unmarshal([]byte(body), &data)
			metadata := data["metadata"].(map[string]interface{})

			foundCatalogCount := metadata["clusterCount"]
			// fmt.Println("Return:", foundCatalogCount)

			// fmt.Println("bool:", foundCatalogCount == float64(expected))
			return foundCatalogCount == float64(expected)

		},
	)
}
