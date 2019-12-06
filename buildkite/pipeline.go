package buildkite

type Pipeline struct {
	Steps []Step `yaml:"steps"`
}
