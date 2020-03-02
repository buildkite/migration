module BK
  module Compat
    class CLI
      require_relative "../compat"
      require "optparse"

      def self.run(command_line)
        options = {}

        option_parser = OptionParser.new do |opts|
          opts.program_name = "buildkite-compat"
          opts.version = BK::Compat::VERSION
          opts.banner = <<~BANNER
          Usage:

              $ buildkite-compat [file] [options]

          Or pass text in via STDIN:

              $ cat [file] > buildkite-compat [options]

          BANNER
        end

        option_parser.parse!

        file = ARGV.pop
        stdin = STDIN.tty? ? nil : $stdin.read

        # Both can't be nil, and both can't be present
        if (!file && !stdin) || (file && stdin)
          puts option_parser
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
