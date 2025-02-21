# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of docker installation commands
      class DockerOrb
        def translate_docker_hadolint(config)
          dockerfiles = config.fetch('dockerfiles', 'Dockerfile').split(':')
          failure_threshold = config.fetch('failure-threshold', 'info')
          ignore_rules = format_rules(config.fetch('ignore-rules', ''), 'ignore')
          trusted_registries = format_rules(config.fetch('trusted-registries', ''), 'trusted-registry')

          [
            'if ! command -v hadolint &> /dev/null; then',
            '# Instead of installing hadolint in a step, ',
            '# we recommend your agent environment to have it pre-installed',
            'echo "~~~ Installing Hadolint"',
            '  if [ "$(uname -s)" = "Darwin" ]; then',
            '    brew install hadolint',
            '  else',
            '    SYS_ARCH=$(uname -m | tr "[:upper:]" "[:lower:]")',
            '    SYS_ARCH=${SYS_ARCH/aarch64/arm64}',
            '    wget -O /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-${SYS_ARCH}"',
            '    chmod +x /usr/local/bin/hadolint',
            '  fi',
            'fi',
            *dockerfiles.map do |dockerfile|
              [
                "echo '~~~ Linting #{dockerfile} with hadolint'",
                "hadolint --failure-threshold #{failure_threshold} #{ignore_rules} #{trusted_registries} #{dockerfile}",
              ]
            end
          ].flatten.compact
        end

        def translate_docker_dockerlint(config)
          dockerfile = config.fetch('dockerfile', 'Dockerfile')
          debug = config.fetch('debug', false)
          treat_warnings_as_errors = config.fetch('treat-warnings-as-errors', false)

          [
            'if ! command -v dockerlint &> /dev/null; then',
            '# Instead of installing dockerlint in a step, ',
            '# we recommend your agent environment to have it pre-installed',
            'echo "~~~ Installing dockerlint"',
            '  if ! command -v npm &> /dev/null; then',
            '    echo "npm is required to install dockerlint."',
            '    echo "Consider running this command with an image that has node available: https://circleci.com/developer/images/image/cimg/node"',
            '    echo "Alternatively, use dockerlint\'s docker image: https://github.com/RedCoolBeans/dockerlint#docker-image."',
            '    exit 1',
            '  fi',
            ('  npm install -g dockerlint' if debug),
            ('  npm install -g dockerlint &> /dev/null' unless debug),
            'fi',
            "dockerlint -f #{dockerfile} #{'-p' if treat_warnings_as_errors}"
          ].compact
        end

        private

        def format_rules(values, flag_type)
          flags = values.split(',').map { |value| "--#{flag_type} #{value.strip}" }.join(' ')
        end
      end
    end
  end
end