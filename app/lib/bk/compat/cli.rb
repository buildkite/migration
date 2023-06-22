# frozen_string_literal: true

module BK
  module Compat
    # Main executable processor
    class CLI
      require_relative '../compat'
      require 'optparse'

      def self.run
        options = {
          runner: 'ELASTIC_CI'
        }

        option_parser = OptionParser.new do |opts|
          opts.program_name = 'buildkite-compat'
          opts.version = BK::Compat::VERSION
          opts.banner = <<~BANNER
            Usage:

                $ buildkite-compat [options] [file(s)]

            Or pass text in via STDIN:

                $ cat [file] > buildkite-compat [options]

          BANNER
          opts.on('-r RUNNNER', '--runner', 'Which runner to target, ELASTIC_CI or ON_DEMAND')
          opts.on('-p PARSER', '--parser', { circleci: BK::Compat::CircleCI, travisci: BK::Compat::TravisCI },
                  'Parser for original pipeline')
        end

        option_parser.parse!(into: options)

        # treat rest of parameters as files (or stdin if none)
        text = ARGF.read

        if text.empty?
          warn 'ERROR: Missing file or input'
          warn option_parser
          exit 1
        end

        # Figure out which parser to use
        parser_klass = options[:parser] || BK::Compat.guess(text)

        # Show a nice error message if we couldn't find a parser to use
        unless parser_klass
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
