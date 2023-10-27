# frozen_string_literal: true

module BK
  module Compat
    # Artifacts to use in a step
    class ArtifactPaths 
      def initialize(paths:)
        # Initialize the @artifact_paths array
        @artifact_paths = paths.split("\n").map(&:strip).reject do |path|
          path.empty? || path.start_with?('!')
        end.map do |path|
          path.end_with?('/') ? path + '**/*' : (File.extname(path).empty? ? path + '/**/*' : path)
        end.uniq
      end
      
      def paths
        base =  @artifact_paths

        base
      end
 
   end
  end
end
