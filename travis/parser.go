package travis

import (
	"log"

	"github.com/buildkite/compat/buildkite"
	yaml "github.com/buildkite/yaml"
)

type Config struct {
	Language string `yaml:"language"`
}

func Parse(input []byte) buildkite.Pipeline {
	// Read the file as YAML
	config := Config{}
	if err := yaml.Unmarshal(input, &config); err != nil {
		log.Panicf("%v", err)
	}

	bk := buildkite.Pipeline{
		Steps: []buildkite.Step{
			buildkite.Step{Command: "test.sh"},
		},
	}

	return bk
}
