require 'cucumber'
require 'botrytis'

module Botrytis
  module CucumberIntegration
    @@step_definitions = []
    @@semantic_matcher = nil
    @@semantic_matches_count = 0
    @@total_step_attempts = 0

    def self.install!
      # Hook into step matching process instead of undefined creation
      Cucumber::Glue::RegistryAndMore.prepend(SemanticStepMatcher)
      
      # Hook into step definition registration to collect them
      Cucumber::Glue::StepDefinition.prepend(StepDefinitionCollector)
      
      # Initialize semantic matcher
      @@semantic_matcher = Botrytis::SemanticMatcher.new
    end

    def self.step_definitions
      @@step_definitions
    end

    def self.semantic_matcher
      @@semantic_matcher
    end

    def self.record_semantic_match!
      @@semantic_matches_count += 1
    end

    def self.record_step_attempt!
      @@total_step_attempts += 1
    end

    def self.semantic_matches_count
      @@semantic_matches_count
    end

    def self.total_step_attempts
      @@total_step_attempts
    end

    def self.print_summary
      if @@semantic_matches_count > 0
        puts "\n🎯 Botrytis Semantic Matching Summary: #{@@semantic_matches_count} fuzzy matches found"
      end
    end

    module StepDefinitionCollector
      def initialize(*args)
        super
        # Add this step definition to our collection
        Botrytis::CucumberIntegration.add_step_definition(self)
      end
    end

    def self.add_step_definition(step_def)
      # Create an adapter to make the step definition compatible with semantic matcher
      adapter = StepDefinitionAdapter.new(step_def)
      @@step_definitions << adapter
    end

    # Adapter to make modern Cucumber StepDefinition compatible with semantic matcher
    class StepDefinitionAdapter
      def initialize(step_def)
        @step_def = step_def
      end

      def regexp_source
        @step_def.expression.to_s
      end

      def proc
        # Create a proc that delegates to the step definition
        lambda { |*args| @step_def.invoke(nil, *args) }
      end

      def method_missing(method, *args, &block)
        @step_def.send(method, *args, &block)
      end

      def respond_to_missing?(method, include_private = false)
        @step_def.respond_to?(method, include_private)
      end
    end

    module SemanticStepMatcher
      def step_matches(name_to_match)
        # First try the normal step matching
        matches = super(name_to_match)
        
        if matches.any?
          return matches
        end
        
        # If no exact matches, try semantic matching
        # Track semantic match attempts
        Botrytis::CucumberIntegration.record_step_attempt!
        semantic_match = attempt_semantic_match(name_to_match)
        
        if semantic_match
          # Semantic match found
          Botrytis::CucumberIntegration.record_semantic_match!
          return [semantic_match]
        else
          # No semantic match found
          return matches # Return empty array, which will result in undefined step
        end
      end

      private

      def attempt_semantic_match(step_name)
        step_definitions = Botrytis::CucumberIntegration.step_definitions
        semantic_matcher = Botrytis::CucumberIntegration.semantic_matcher
        
        return nil if step_definitions.empty? || semantic_matcher.nil?
        
        # Use the semantic matcher to find a match
        match = semantic_matcher.find_match(step_name, step_definitions)
        
        return match if match
        nil
      end
    end
  end
end

# Install the semantic matching when this file is loaded
Botrytis::CucumberIntegration.install!

# Print summary at exit
at_exit do
  Botrytis::CucumberIntegration.print_summary
end
