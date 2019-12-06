package travis

import (
	"fmt"
	"log"

	"github.com/buildkite/compat/buildkite"
	yaml "github.com/buildkite/yaml"
)

// https://config.travis-ci.com

type Jobs struct {
	Include       map[string]interface{}
	Exclude       map[string]interface{}
	AllowFailures map[string]interface{}
	FastFinish    bool
}

type Config struct {
	Language      string   `yaml:"language"`
	Cache         string   `yaml:"cache"`
	BeforeInstall []string `yaml:"before_install"`

	Matrix Jobs `yaml:"matrix"`
	Jobs   Jobs `yaml:"jobs"`
}

func Parse(input []byte) buildkite.Pipeline {
	// Read the file as YAML
	var parsed map[string]interface{}
	if err := yaml.Unmarshal(input, &parsed); err != nil {
		log.Panicf("%v", err)
	}

	config := Config{}

	config.BeforeInstall = parsed["before_install"]
	delete(parsed, "before_install")

	fmt.Printf("%v", parsed)

	bk := buildkite.Pipeline{
		Steps: []buildkite.Step{
			buildkite.Step{Commands: config.BeforeInstall},
		},
	}

	return bk
}
