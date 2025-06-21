require 'cucumber/formatter/console'

module Botrytis
  class Formatter
    include Cucumber::Formatter::Console

    def initialize(config)
      @config
      @semantic_matcher = SemanticMatcher.new

      @step_definitions = []

      config.on_step_definition do |step_definition|
        @step_definitions << step_definition
      end

      register_semantic_matcher
    end

    def register_semantic_matcher
      @original_match_method = Cucumber::Glue::StepDefinitionLight.instance_method(:match)

      semantic_matcher = @semantic_matcher
      step_definitions = @step_definitions

      Cucumber::Glue::StepDefinitionLight.define_method(:match) do |step_name|
        result = @original_match_method.bind(self).call(step_name)

        if result.nil?
          puts "\n Botrytis is looking for a fuzzy match for :\"#{step_name}\""

          match = semantic_matcher.find_match(step_name, step_definitions)

          if match && match_confidence >= Botrytis.configuration.confidence_threshold
            puts "Found a match"
            return match
          end
        end

        result
      end
    end
  end
end
