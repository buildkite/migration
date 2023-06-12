module BK
  module Compat
    class CLI
      require_relative "../compat"
      require "optparse"

      def self.run(command_line)
        options = {
          runner: "ELASTIC_CI",
        }

        option_parser = OptionParser.new do |opts|
          opts.program_name = "buildkite-compat"
          opts.version = BK::Compat::VERSION
          opts.banner = <<~BANNER
          Usage:

              $ buildkite-compat [file] [options]

          Or pass text in via STDIN:

              $ cat [file] > buildkite-compat [options]

          BANNER
          opts.on("-r RUNNNER", "--runner", "Which runner to target, ELASTIC_CI or ON_DEMAND")
          opts.on("-p PARSER", "--parser", "Parser for original pipeline")
        end

        option_parser.parse!(into: options)

        # Either get the file from the arguments, or read STDIN
        file = ARGV.pop
        text = STDIN.tty? ? nil : $stdin.read

        # Ensure only one is present
        if !(file.nil? ^ text.nil?)
          puts option_parser
          exit 1
        end

        if file
          text = File.read(file)
        end

        # Figure out which parser to use
        parser_klass = BK::Compat.guess(text)

        # Show a nice error message if we couldn't find a parser to use
        if !parser_klass
          puts <<~TEXT
          Not sure which parser to use. Compatible parsers are:

          #{BK::Compat::PARSERS.map { |parser_klass| " - #{parser_klass.name}" }.join("\n")}
          TEXT

          exit 1
        end

        # Now we can finally parse and render the thing
        puts parser_klass.new(text, options).parse.render
      end
    end
  end
end
