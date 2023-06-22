# frozen_string_literal: true

module BK
  module Compat
    # Main executable processor
    class CLI
      require_relative '../compat'
      require 'optparse'

      def self.parse_options
        options = {
          runner: 'ELASTIC_CI'
        }

        parsers = Hash[
          BK::Compat::PARSERS.collect { |v| [ v.option, v ] }
        ]

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
          opts.on('-p PARSER', '--parser', parsers, "Parser for original pipeline (#{parsers.keys})")
        end

        option_parser.parse!(into: options)

        # treat rest of parameters as files (or stdin if none)
        options[:text] = ARGF.read

        if options[:text].empty?
          warn 'ERROR: Missing file or input'
          warn option_parser
          exit 1
        end

        options
      end

      def self.run
        options = parse_options

        # Figure out which parser to use
        parser_klass = options[:parser] || BK::Compat.guess(options[:text])

        # Show a nice error message if we couldn't find a parser to use
        unless parser_klass
          puts <<~TEXT
            Not sure which parser to use. Compatible parsers are:

            #{BK::Compat::PARSERS.map { |klass| " - #{klass.name}" }.join("\n")}
          TEXT

          exit 1
        end

        # Now we can finally parse and render the thing
        puts parser_klass.new(options[:text], options).parse.render
      end
    end
  end
end
