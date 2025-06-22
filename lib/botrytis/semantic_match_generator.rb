require 'sublayer'

module Botrytis
  class SemanticMatchGenerator < Sublayer::Generators::Base
    llm_output_adapter type: :named_strings,
      name: "step_match_result",
      description: "Results of semantic matching for a cucumber step",
      attributes: [
        { name: "step_text_analysis", description: "Analysis of the step text, including semantic meaning and intent" },
        { name: "match_found", description: "Indicates if a match was found, either the string yes or no" },
        { name: "best_match_pattern", description: "The pattern that best matches semantically" },
        { name: "confidence", description: "Confidence score of the match (0.0 - 1.0)" },
        { name: "parameter_values", description: "A comma separated list of parameter values extracted from the match" }
      ]

      def initialize(step_text:, available_patterns:)
        @step_text = step_text
        @available_patterns = available_patterns
      end

      def generate
        super
      end

      def prompt
        <<-PROMPT
        You are a semantic matcher for Cucumber step definitions. Your task is to determine if a step text semantically matches one of the available regex patterns, even if it doesn't match exactly.

        Step Text: "#{@step_text}"

        Available Step Definition Patterns:
        #{@available_patterns.join("\n")}

        For each pattern, consider:
        1. The semantic meaning/intent of the step
        2. The structure of the pattern
        3. Any parameters that would need to be extracted

        Choose the pattern that best matches the step text semantically.
        If no pattern is a good semantic match, indicate that no match was found.

        If you find a match, extract any parameters that would be captured by the pattern. And return them as a comma separated list.
        For example, if the pattern is "I have (\\d+) cucumbers" and the step is "I have 5 cucumbers",
        the parameter value would be "5".

        Provide your confidence in the match as a value between 0.0 (no confidence) and 1.0 (absolute certainty).
        PROMPT
      end
  end
end
