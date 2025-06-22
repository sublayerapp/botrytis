require 'cucumber/formatter/console'
require_relative '../botrytis'

module Botrytis
  class Formatter
    include Cucumber::Formatter::Console

    def initialize(config)
      @config = config
      
      # Initialize Botrytis configuration if not already done
      unless defined?(Botrytis.configuration)
        Botrytis.configure do |botrytis_config|
          botrytis_config.confidence_threshold = 0.7
          botrytis_config.cache_enabled = false
          botrytis_config.llm_provider = :openai
          botrytis_config.model_name = "gpt-4o"
        end
      end
      
      @semantic_matcher = SemanticMatcher.new
      @step_definitions = []

      # Use the modern event system to collect step definitions
      config.on_event(:step_definition_registered) do |event|
        @step_definitions << event.step_definition
      end

      # Register semantic matcher once all setup is done
      config.on_event(:test_run_started) do |event|
        register_semantic_matcher
      end
    end

    def register_semantic_matcher
      # Find the correct StepDefinition class to monkey patch
      step_def_class = if defined?(Cucumber::Glue::StepDefinition)
                         Cucumber::Glue::StepDefinition
                       elsif defined?(Cucumber::StepDefinition)
                         Cucumber::StepDefinition
                       else
                         # Try to find any step definition class
                         Cucumber.constants.select do |c|
                           Cucumber.const_get(c).is_a?(Class) && c.to_s.include?('Step')
                         end.first&.then { |c| Cucumber.const_get(c) }
                       end

      return unless step_def_class

      @original_match_method = step_def_class.instance_method(:match)

      semantic_matcher = @semantic_matcher
      step_definitions = @step_definitions

      step_def_class.define_method(:match) do |step_name|
        result = @original_match_method.bind(self).call(step_name)

        if result.nil?
          puts "\n🥒 Botrytis is looking for a fuzzy match for: \"#{step_name}\""

          match = semantic_matcher.find_match(step_name, step_definitions)

          if match
            puts "✅ Found a semantic match!"
            return match
          else
            puts "❌ No semantic match found"
          end
        end

        result
      end
    end
  end
end
