module BK
  module Compat
    class CLI
      require_relative "../compat"

      BANNER = "Usage: buildkite-compat [file] or pass text in via STDIN"

      def self.run(command_line)
        file = command_line[0]

        # Really hacky option parsing
        if file == "--version"
          puts "buildkite-compat version #{BK::Compat::VERSION}"
          exit 0
        end
        if file == "--help"
          puts BANNER
          exit 0
        end

        stdin = STDIN.tty? ? nil : $stdin.read

        # Both can't be nil, and both can't be present
        if (!file && !stdin) || (file && stdin)
          puts BANNER
          exit 1
        end

        parsed = if file
                   BK::Compat::CircleCI.parse_file(file)
                 else
                   BK::Compat::CircleCI.parse_text(stdin)
                 end

        puts parsed.render
      end
    end
  end
end
