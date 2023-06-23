# frozen_string_literal: true

module BK
  module Compat
    # unsupported feature
    module Error
      class NotSupportedError < StandardError; end
    end
  end
end
