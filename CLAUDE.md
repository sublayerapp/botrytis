# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Botrytis is a Ruby gem that provides LLM-powered semantic matching for Cucumber step definitions. It enables fuzzy matching of Cucumber steps using large language models, making BDD tests more flexible by matching similar but not exact step text.

## Architecture

### Core Components

- **SemanticMatcher** (`lib/botrytis/semantic_matcher.rb`): Main matching engine that finds semantic matches between step text and available step definitions using LLMs
- **SemanticMatchGenerator** (`lib/botrytis/semantic_match_generator.rb`): LLM interaction layer built on Sublayer for generating semantic matches
- **Configuration** (`lib/botrytis/configuration.rb`): Configurable settings for LLM provider, model, confidence thresholds, and caching
- **Formatter** (`lib/botrytis/formatter.rb`): Custom Cucumber formatter integration

### Key Dependencies

- **cucumber**: Core Cucumber framework (>= 9)
- **sublayer**: LLM abstraction layer (>= 0.2.8) for AI provider interactions
- **rspec**: Testing framework

### Configuration System

The gem supports configuration of:
- LLM provider (default: :openai)
- Model name (default: "gpt-4o") 
- Confidence threshold (default: 0.7)
- Caching enabled/disabled (default: true)
- Cache directory (default: ".botrytis_cache")

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rake spec
# or
bundle exec rspec

# Run specific test files
bundle exec rspec spec/botrytis_spec.rb

# Run with specific options
bundle exec rspec --fail-fast
```

### Building and Installation
```bash
# Build the gem
bundle exec rake build

# Install locally
bundle exec rake install:local

# Clean build artifacts
bundle exec rake clean
```

### Development Setup
```bash
# Install dependencies
bundle install

# Run interactive console with gem loaded
bundle exec irb -r botrytis
```

## Semantic Matching Flow

1. Step text is compared against available step definition patterns
2. If caching is enabled, check for cached results first
3. Query LLM through Sublayer with step text and available patterns
4. LLM returns confidence score and best match pattern
5. If confidence meets threshold, return Cucumber::Glue::StepMatch
6. Cache result if caching enabled

## File Structure Notes

- Main entry point: `lib/botrytis.rb`
- Core logic in `lib/botrytis/` directory
- RSpec tests in `spec/` directory
- Gem configuration in `botrytis.gemspec`
- Rake tasks defined in `Rakefile` (default task is `:spec`)