module Botrytis
  class Configuration
    attr_accessor :llm_provider, :model_name, :confidence_threshold, :cache_enabled, :cache_directory

    def initialize
      @llm_provider = :openai
      @model_name = "gpt-4o"
      @confidence_threshold = 0.7
      @cache_enabled = true
      @cache_directory = File.join(Dir.pwd, ".botrytis_cache")
    end
  end
end
