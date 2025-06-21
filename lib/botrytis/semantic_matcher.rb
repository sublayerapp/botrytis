require 'digest'
require 'fileutils'
require 'json'
require 'botrytis/semantic_match_generator'

module Botrytis
  class SemanticMatcher
    def initialize
      ensure_cache_directory if Botrytis.configuration.cache_enabled
    end

    def find_match(step_text, available_step_definitions)
      patterns = available_step_definitions.map do  |step_def|
        {
          pattern: step_def.regexp_source,
          proc: step_def.proc,
          step_def: step_def
        }
      end

      if Botrytis.configuration.cache_enabled
        cache_result = check_cache(step_text, patterns.map { |p| p[:pattern] })
        return cache_result if cache_result
      end

      match_result = query_llm(step_text, patterns.map { |p| p[:pattern] })

      save_to_cache(step_text, patterns.map { |p| p[:pattern] }, match_result) if Botrytis.configuration.cache_enabled

      if match_result.match_found == "yes" && match_result.confidence.to_f >= Botrytis.configuration.confidence_threshold

        matching_pattern = patterns.find { |p| p[:pattern] == match_result.best_match_pattern }

        if matching_pattern
          return create_match_result(matching_pattern[:step_def], step_text, match_result.parameter_values)
        end
      end

      nil
    end

    private

    def query_llm(step_text, patterns)
      generator = SemanticMatchGenerator.new(
        step_text: step_text,
        available_patterns: patterns
      )

      Sublayer.configuration.ai_provider = Botrytis.configuration.llm_provider
      Sublayer.configuration.ai_model = Botrytis.configuration.model_name

      generator.generate
    end

    def ensure_cache_directory
      FileUtils.mkdir_p(Botrytis.configuration.cache_directory) unless Dir.exist?(Botrytis.configuration.cache_directory)
    end

    def cache_key(step_text, patterns)
      Digest::MD5.hexdigest("#{step_text}-#{patterns.sort.join('-')}")
    end

    def check_cache(step_text, patterns)
      key = cache_key(step_text, patterns)
      cache_file = File.join(Botrytis.configuration.cache_directory, "#{key}.json")

      if File.exist?(cache_file)
        data = JSON.parse(File.read(cache_file))
      end

      nil
    end

    def create_match_result(step_definition, step_text, parameter_values)
      Cucumber::Glue::StepMatch.new(step_definition, step_text, parameter_values)
    end
  end
end
