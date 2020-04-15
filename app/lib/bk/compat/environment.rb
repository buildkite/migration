
module BK
  module Compat
    class Environment
      EMPTY = ""

      SPLIT_REGEX = /\r?\n/

      ENV_LINE_REGEX = /([^=]+)=(.*)/

      EXPORT_REGEX = /\Aexport /
      KEY_REGX = /\A[a-zA-Z0-9_]+\z/

      DOUBLE_QUOTE_REGEX = /\A"([.\s\S]*)"\z/
      SINGLE_QUOTE_REGEX = /\A'([.\s\S]*)'\z/

      def initialize(value)
        @value = value
      end

      def variables
        @variables ||= parse(@value)
      end

      def set(key, value)
        variables[key] = value
      end

      def merge(other)
        other_env = if other.is_a?(self.class)
                      other
                    else
                      self.class.new(other)
                    end

        other_env.each do |(key, value)|
          set(key, value)
        end

        self
      end

      def each(&block)
        variables.each(&block)
      end

      def empty?
        variables.empty?
      end

      def to_s
        (+"").tap do |env_as_text|
          to_h.each.with_index do |(key, value), index|
            env_as_text << "\n" unless index.zero?
            env_as_text << key.to_s << "=" << value.to_s.gsub("\n", "\\n").inspect
          end
        end
      end

      def to_h
        variables
      end

      def inspect
        "#<BK::Compat::Environment variables=#{to_h.inspect}"
      end

      private

      def parse(text)
        return nil if text.nil? || text.empty?
        return text if text.is_a?(Hash)

        lines = if text.is_a?(Array)
                  text.join("\n\n")
                else
                  text
                end.split(SPLIT_REGEX)

        lines.inject({}) do |env, line|
          parts = line.match(ENV_LINE_REGEX)

          key = $1.to_s.strip
          value = $2.to_s.strip

          # Skip if the key is blank
          next env if key.empty?

          # Filter out any export in "export FOO=bar"
          key = key.gsub(EXPORT_REGEX, "")

          # Only if the key looks like something we expect
          if key.match?(KEY_REGX)
            # Default the value to an empty string if nothing is there
            if value.empty?
              env[key] = EMPTY
            else
              # Filter out surrounding quotes
              if value =~ DOUBLE_QUOTE_REGEX || value =~ SINGLE_QUOTE_REGEX
                value = $1
              end

              # Replace \\n with real lines
              value.gsub!("\\n", "\n")

              # Finally set the value
              env[key] = value
            end
          end

          env
        end
      end
    end
  end
end
