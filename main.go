package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/buildkite/compat/travis"
	yaml "github.com/buildkite/yaml"
)

func main() {
	// Read the file from STDIN
	input, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		log.Fatal("Failed to read from STDIN: %s", err)
	}

	// Parse it as a .travis.yml config and turn it into a config that BK
	// can understand
	bk := travis.Parse(input)

	// Spit the result out as YAML again
	output, err := yaml.Marshal(&bk)
	if err != nil {
		log.Fatalf("error: %v", err)
	}
	fmt.Print(string(output))
}
