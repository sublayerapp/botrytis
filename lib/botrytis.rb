# frozen_string_literal: true

require_relative "botrytis/version"
require_relative "botrytis/semantic_matcher"
require_relative "botrytis/configuration"
require_relative "botrytis/formatter"

module Botrytis
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
