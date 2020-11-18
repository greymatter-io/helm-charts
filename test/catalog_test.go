package test

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

func TestCatalog(t *testing.T) {
	kubectlOptions := k8s.NewKubectlOptions("", "", "default")

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
	certPem, err := ioutil.ReadFile("/Users/chris/.ssh/di2e/chris.smith/server.crt")
	if err != nil {
		log.Fatal(err)
	}
	keyPem, err := ioutil.ReadFile("/Users/chris/.ssh/di2e/chris.smith/server.key")
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
	catalogEndpoint := "https://mesh.greymatter.devcloud.di2e.net/services/catalog/latest/summary"

	expected := 40
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
			fmt.Println("Return:", foundCatalogCount)

			fmt.Println("bool:", foundCatalogCount == float64(expected))
			return foundCatalogCount == float64(expected)

			// if foundCatalogCount != 39 {
			// 	return false
			// }

			// // return statusCode == 200
			// return true
		},
	)
}

// // MarshalInterfaceToString accepts an input interface and returns either the raw string
// // or serialized json string representation of the object passed in
// func MarshalInterfaceToString(aInterface interface{}) (string, error) {
// 	// If no value provided, return empty
// 	if aInterface == nil {
// 		return "", nil
// 	}
// 	if reflect.TypeOf(aInterface).Kind().String() == "string" {
// 		// The interface is a string, return directly
// 		return aInterface.(string), nil
// 	}
// 	// The interface is an object, serialize to a string
// 	aInterfaceBytes, err := json.Marshal(aInterface)
// 	if err != nil {
// 		return "", err
// 	}
// 	return string(aInterfaceBytes[:]), nil
// }

// // UnmarshalStringToInterface takes a serialized string and unmarshal to a json object
// func UnmarshalStringToInterface(astring string) (interface{}, error) {
// 	var result interface{}
// 	if err := json.Unmarshal([]byte(astring), &result); err != nil {
// 		return result, err
// 	}
// 	return result, nil
// }

// // NormalizeMarshalledInterface leverages json unmarshal and marshal to normalize interface in alpha order
// func NormalizeMarshalledInterface(i string) (string, error) {
// 	var normalizedInterface interface{}
// 	if err := json.Unmarshal([]byte(i), &normalizedInterface); err != nil {
// 		return i, err
// 	}
// 	normalizedBytes, err := json.Marshal(normalizedInterface)
// 	if err != nil {
// 		return i, err
// 	}
// 	return string(normalizedBytes[:]), nil
// }

// // UnmarshalStringToMap takes a serialized string and unmarshals to a json object and then converts to a map
// func UnmarshalStringToMap(astring string) (map[string]interface{}, error) {
// 	i, err := UnmarshalStringToInterface(astring)
// 	if err != nil {
// 		return nil, err
// 	}
// 	oMap, ok := i.(map[string]interface{})
// 	if !ok {
// 		return nil, fmt.Errorf("could not convert interface to map")
// 	}
// 	return oMap, nil
// }
