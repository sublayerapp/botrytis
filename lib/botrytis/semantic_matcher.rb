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
          return Cucumber::StepMatch.new(step_definition, step_text, step_arguments)
        else
          # Fallback to manual creation
          step_arguments = create_step_arguments(step_definition, parameter_values)
          return Cucumber::StepMatch.new(step_definition, step_text, step_arguments)
        end
      rescue => e
        # Error in create_match_result, falling back
        # Fallback to simple creation with empty arguments
        return Cucumber::StepMatch.new(step_definition, step_text, [])
      end
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

      # Replace capture groups with actual parameter values
      pattern = regex.source
      parameter_values.each do |value|
        # Replace the first capture group with the actual value
        pattern = pattern.sub(/\([^)]+\)/, value)
      end

      # Clean up anchors
      pattern.gsub(/[\^$]/, '')
    end

    def create_step_arguments(step_definition, parameter_values)
      # If no parameters, return empty arguments
      return [] if parameter_values.nil? || parameter_values.empty?

      # For semantic matching, we need to create step arguments that Cucumber can understand
      # The issue is that Cucumber expects MatchData-like objects, but we have strings
      # Let's try to create a proper match by actually running the target step definition
      # against a constructed step text that would match and produce the right parameters

      # Get the original step definition's regex pattern
      begin
        # Extract the regex from the step definition
        if step_definition.respond_to?(:expression) && step_definition.expression.is_a?(Regexp)
          regex = step_definition.expression
        elsif step_definition.respond_to?(:regexp_source)
          # Parse the regexp_source string back into a Regexp
          source = step_definition.regexp_source.to_s
          # Remove the leading /^ and trailing $/ if present
          source = source.gsub(/^\/\^/, '').gsub(/\$\/$/, '')
          regex = Regexp.new("^#{source}$")
        else
          # Fallback - just return the parameter values as-is
          return parameter_values
        end

        # Try to construct a step text that would match the regex and produce our desired parameters
        constructed_step_text = construct_matching_step_text(regex, parameter_values)

        # Now match this constructed text against the regex to get proper MatchData
        match_data = regex.match(constructed_step_text)

        if match_data
          # Extract the captured groups (skip the full match at index 0)
          return match_data.captures
        else
          # Fallback to original parameter values
          return parameter_values
        end

      rescue => e
        # If anything goes wrong, fallback to original parameter values
        return parameter_values
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
  end
end
