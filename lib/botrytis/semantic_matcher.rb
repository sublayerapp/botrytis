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

      # Filter out test verification steps for semantic matching
      # These are steps that end with "should have executed" or similar test patterns
      business_patterns = patterns.reject do |p|
        pattern_text = p[:pattern].to_s
        pattern_text.include?("should have executed") ||
        pattern_text.include?("configured for testing") ||
        pattern_text.include?("test") ||
        pattern_text.include?("verification")
      end

      # Use business patterns for LLM matching, but keep all patterns for final matching
      query_patterns = business_patterns.empty? ? patterns : business_patterns

      if Botrytis.configuration.cache_enabled
        cache_result = check_cache(step_text, patterns.map { |p| p[:pattern] })
        return cache_result if cache_result
      end

      match_result = query_llm(step_text, query_patterns.map { |p| p[:pattern] })

      save_to_cache(step_text, patterns.map { |p| p[:pattern] }, match_result) if Botrytis.configuration.cache_enabled

      if match_result.match_found == "yes" && match_result.confidence.to_f >= Botrytis.configuration.confidence_threshold

        # Handle different pattern formats from LLM response
        # The LLM might return escaped quotes or slightly different formats
        matching_pattern = patterns.find do |p| 
          original_pattern = p[:pattern]
          llm_pattern = match_result.best_match_pattern
          
          # Try exact match first
          original_pattern == llm_pattern ||
          # Try with/without surrounding slashes
          original_pattern == "/#{llm_pattern}/" ||
          original_pattern.gsub(/^\/|\/$/,'') == llm_pattern.gsub(/^\/|\/$/,'') ||
          # Try with unescaped quotes (LLM might escape them)
          original_pattern == llm_pattern.gsub(/\\\"/, '"') ||
          original_pattern.gsub(/^\/|\/$/,'') == llm_pattern.gsub(/^\/|\/$/,'').gsub(/\\\"/, '"')
        end

        if matching_pattern
          # Convert comma-separated parameter_values string to array
          parameter_values = if match_result.parameter_values.nil? || match_result.parameter_values.empty?
                              []
                            else
                              match_result.parameter_values.split(',').map(&:strip)
                            end
          return create_match_result(matching_pattern[:step_def], step_text, parameter_values)
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

      case Botrytis.configuration.llm_provider
      when :openai
        Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
      when :claude
        Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
      when :gemini
        Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
      end

      Sublayer.configuration.ai_model = Botrytis.configuration.model_name

      begin
        result = generator.generate
        result
      rescue => e
        # LLM API Error occurred, falling back to no match
        # Return a "no match" response if API fails
        OpenStruct.new(
          match_found: "no",
          best_match_pattern: "",
          confidence: "0.0",
          parameter_values: ""
        )
      end
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
      # Instead of trying to manually create step arguments, let's use Cucumber's
      # normal matching mechanism by having the step definition actually match
      # a constructed step text that would produce the right parameters

      begin
        # Try to construct a step text that the step definition would actually match
        constructed_step_text = construct_matching_step_text_for_step_def(step_definition, parameter_values)

        # Use the step definition's normal matching mechanism
        if step_definition.respond_to?(:arguments_from)
          # This is the normal way Cucumber creates step matches
          step_arguments = step_definition.arguments_from(constructed_step_text)
          return SemanticStepMatch.new(step_definition, step_text, step_arguments)
        else
          # Fallback to manual creation
          step_arguments = create_original_step_arguments(step_definition, parameter_values)
          return SemanticStepMatch.new(step_definition, step_text, step_arguments)
        end
      rescue => e
        # Error in create_match_result, falling back
        # Fallback to simple creation with empty arguments
        return SemanticStepMatch.new(step_definition, step_text, [])
      end
    end

    def create_proper_step_arguments(step_definition, step_text, parameter_values)
      # Create step arguments that don't interfere with display formatting
      # For semantic matching, we just need the parameter values to be passed to the step
      # We don't need complex MatchData objects since Cucumber will handle display
      return parameter_values || []
    end

    def construct_matching_step_text_for_step_def(step_definition, parameter_values)
      # This creates a step text that would actually match the step definition's regex
      # and produce the desired parameter values

      if parameter_values.nil? || parameter_values.empty?
        # For steps without parameters, just use the regexp source without anchors
        if step_definition.respond_to?(:regexp_source)
          source = step_definition.regexp_source.to_s
          return source.gsub(/^\/\^/, '').gsub(/\$\/$/, '').gsub(/[\^$\/]/, '')
        end
      end

      # For the button example: /^they click the "([^"]*)" button$/
      # We want to produce: they click the "Buy Now" button
      # So that when matched, it captures "Buy Now"

      if step_definition.respond_to?(:expression) && step_definition.expression.is_a?(Regexp)
        regex = step_definition.expression
      elsif step_definition.respond_to?(:regexp_source)
        source = step_definition.regexp_source.to_s.gsub(/^\/\^/, '').gsub(/\$\/$/, '')
        regex = Regexp.new("^#{source}$")
      else
        # Fallback - return something simple
        return parameter_values.join(' ')
      end

      # Better approach: build step text by understanding the regex structure
      pattern = regex.source
      
      # For simple cases like they click the "([^"]*)" button
      # We want to replace ([^"]*) with the actual parameter value
      if pattern.include?('"([^"]*)"') && parameter_values.length == 1
        # Handle quoted parameter patterns specifically
        result = pattern.gsub(/\([^)]+\)/, parameter_values[0])
      else
        # Fallback to general replacement
        parameter_values.each do |value|
          pattern = pattern.sub(/\([^)]+\)/, value)
        end
        result = pattern
      end

      # Clean up anchors and regex chars
      result.gsub(/[\^$]/, '').gsub(/^\//, '').gsub(/\/$/, '')
    end

    def create_original_step_arguments(step_definition, parameter_values)
      # For semantic matching, create simple argument objects that work with Cucumber
      # This avoids the complex text construction that causes display issues
      return [] if parameter_values.nil? || parameter_values.empty?
      
      # Create simple argument objects that just hold the parameter values
      # without trying to map them to text positions
      parameter_values.map do |value|
        # Create a minimal object that responds to the methods Cucumber expects
        StepArgument.new(value)
      end
    end

    # Minimal step argument class for semantic matching
    class StepArgument
      def initialize(value)
        @value = value
      end

      def group(index = 0)
        index == 0 ? @value : nil
      end

      def to_s
        @value.to_s
      end

      def value
        @value
      end

      def captures
        [@value]
      end
    end

    def construct_matching_step_text(regex, parameter_values)
      # This is a simple approach: take the regex pattern and substitute
      # capture groups with our parameter values
      pattern = regex.source

      # Replace capture groups like ([^"]*) with actual values
      parameter_values.each_with_index do |value, index|
        # Replace the first capture group with the parameter value
        pattern = pattern.sub(/\([^)]+\)/, value)
      end

      # Clean up the pattern to make it a valid step text
      pattern = pattern.gsub(/[\^$]/, '') # Remove anchors
      pattern
    end

    # Custom StepMatch class for semantic matches that avoids display corruption
    # The core issue is that Cucumber tries to highlight parameters in step text 
    # based on parameter positions from the constructed text, but the positions
    # don't align with the original step text, causing garbled display.
    class SemanticStepMatch < Cucumber::StepMatch
      def replace_arguments(step_name, format, colour)
        # For semantic matches, don't try to replace/highlight arguments
        # Just return the original step name to avoid garbled text from
        # parameter position mismatches
        step_name
      end
    end

  end
end
