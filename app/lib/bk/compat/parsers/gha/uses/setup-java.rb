# frozen_string_literal: true

module BK
  module Compat
    class GHABuiltins

      def obtain_java_distribution_image(distribution, java_version)
        case distribution
        # seemru, adopt-openj9 (moved to seemru)
        when /semeru|adopt-openj9/
          "ibm-semeru-runtimes:open-#{java_version}-jdk"
        # temurin, adpot (moved to temurin), oracle (deprecated)
        when /temurin|adopt|oracle/
          "eclipse-temurin:#{java_version}-jdk-alpine"
        when /zulu/
          "azul/zulu-openjdk-alpine:t#{java_version}-latest"
        when /liberica/
          "bellsoft/liberica-openjdk-alpine:#{java_version}"
        when /microsoft/
          "mcr.microsoft.com/openjdk/jdk:#{java_version}-ubuntu"
        when /coretto/
          "amazoncorretto:#{java_version}-al2023-jdk"
        when /dragonwell/
          "alibabadragonwell/dragonwell:#{java_version}-alpine"
        end
      end
    end
  end
end
    