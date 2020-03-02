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
        text = STDIN.tty? ? nil : $stdin.read

        # Both can't be nil, and both can't be present
        if (!file && !text) || (file && text)
          puts option_parser
          exit 1
        elsif file && !text
          text = File.read(file)
        end

        parser_klass = BK::Compat.guess(text)

        if parser_klass
          puts parser_klass.new(text).parse.render
        else
          puts <<~TEXT
          Not sure which parser to use. Compatible parsers are:

          #{BK::Compat::PARSERS.map { |parser_klass| " - #{parser_klass.name}" }.join("\n")}
          TEXT

          exit 1
        end
      end
    end
  end
end
