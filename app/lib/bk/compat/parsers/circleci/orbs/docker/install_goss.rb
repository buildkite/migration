# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Handles the translation of Goss installation commands
      class DockerOrb
        def translate_docker_install_goss(config)
          arch = config.fetch('architecture', 'amd64')
          install_dir = config.fetch('install-dir', '/usr/local/bin')
          version = config.fetch('version', 'latest')

          [
            "echo '~~~ Installing Goss and dgoss'",
            "arch=\"#{arch}\"",
            "version=\"#{version}\"",
            "install_dir=\"#{install_dir}\"",
            'if [ "${version}" = "latest" ]; then',
            '  VERSION=$(curl -Ls --fail --retry 3 -o /dev/null -w "%<url_effective>s" ' \
            'https://github.com/aelsabbahy/goss/releases/latest | sed "s:.*/::")',
            '  echo "Latest version of Goss is ${VERSION}"',
            'else',
            ' VERSION="${version}"',
            '  echo "Selected version of Goss is ${VERSION}"',
            'fi',
            'curl -sSLo "${install_dir}/goss" "https://github.com/aelsabbahy/goss/releases/download/$VERSION/goss-linux-${arch}"',
            'mv goss-linux-${arch} "${install_dir}/goss"',
            'chmod +rx "${install_dir}/goss"',
            'DGOSS_URL="https://raw.githubusercontent.com/aelsabbahy/goss/$VERSION/extras/dgoss/dgoss"',
            'curl -fsSL "${DGOSS_URL}" -o "${install_dir}/dgoss" || ' \
            'echo "No dgoss wrapper found for the selected version of Goss ($VERSION)."',
            %(chmod +rx "${install_dir}/dgoss")
          ]
        end
      end
    end
  end
end
