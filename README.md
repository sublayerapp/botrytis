# Botrytis

[![Gem Version](https://badge.fury.io/rb/botrytis.svg)](https://badge.fury.io/rb/botrytis)

**LLM-powered semantic matching for your Cucumber steps**

Botrytis makes your BDD tests more flexible by using Large Language Models to match semantically similar Cucumber steps, even when they don't match exactly.

## What it does

Instead of your Cucumber tests failing when step text doesn't match exactly:

```gherkin
# ❌ This fails without Botrytis
Given the user has authenticated successfully  # No matching step definition

# ✅ But this step definition exists:
Given(/^the user has logged in to their account$/) do
  # implementation
end
```

With Botrytis, the LLM understands that "authenticated successfully" and "logged in to their account" are semantically equivalent, so your test passes!

## Features

- 🧠 **Semantic step matching** using OpenAI, Claude, or Gemini
- 🎯 **Confidence-based matching** with configurable thresholds
- ⚡ **Intelligent caching** to avoid repeated LLM calls
- 🔄 **Parameter extraction** from semantically matched steps
- 📊 **Match reporting** shows how many fuzzy matches were found
- 🧪 **Live API testing** mode for development

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'botrytis'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install botrytis
```

## Quick Start

1. **Add to your Cucumber support files**:

```ruby
# features/support/env.rb
require 'botrytis/cucumber'
```

2. **Configure your LLM provider** (create `features/support/botrytis.rb`):

```ruby
require 'botrytis'

Botrytis.configure do |config|
  config.llm_provider = :openai  # or :claude, :gemini
  config.model_name = "gpt-4o"
  config.confidence_threshold = 0.7
  config.cache_enabled = true
end
```

3. **Set your API key** (e.g., in `.env` or environment):

```bash
export OPENAI_API_KEY=your_api_key_here
```

4. **Run your tests** and see semantic matching in action! 

```bash
$ bundle exec cucumber

# Output shows:
# 6 scenarios (6 passed)
# 24 steps (24 passed)
# 🎯 Botrytis Semantic Matching Summary: 10 fuzzy matches found
```

## Examples

### Authentication Variations

```gherkin
# All of these match the same step definition:
Given the user has logged in to their account      # Exact match
Given the user has authenticated successfully      # Semantic match ✨
Given the user has signed in to their account      # Semantic match ✨
```

### Action Variations

```gherkin
# Step definition:
When(/^they click the "([^"]*)" button$/) do |button_name|
  # implementation
end

# These all work:
When they click the "Buy Now" button               # Exact match
When they press the "Buy Now" button               # Semantic match ✨  
When they tap the "Buy Now" button                 # Semantic match ✨
When they hit the purchase button                  # Semantic match ✨
When they mash the buy button                      # Semantic match ✨
When they gently caresses the "Buy Now" button     # Semantic match ✨
```

### Assertion Variations

```gherkin
# Step definition:
Then(/^they should see a confirmation message$/) do
  # implementation  
end

# These all work:
Then they should see a confirmation message         # Exact match
Then they should view a confirmation message        # Semantic match ✨
Then they receive a success notification           # Semantic match ✨
Then they get a notification                       # Semantic match ✨
```

## Configuration

```ruby
Botrytis.configure do |config|
  # LLM Provider (required)
  config.llm_provider = :openai     # :openai, :claude, or :gemini
  
  # Model name (required)
  config.model_name = "gpt-4o"      # or "claude-3-sonnet", "gemini-pro", etc.
  
  # Confidence threshold (0.0 - 1.0)
  config.confidence_threshold = 0.7  # Only matches above this confidence
  
  # Caching
  config.cache_enabled = true        # Cache LLM responses  
  config.cache_directory = ".botrytis_cache"  # Cache location
end
```

### LLM Provider Setup

**OpenAI**:
```ruby
config.llm_provider = :openai
config.model_name = "gpt-4o"  # or "gpt-4", "gpt-3.5-turbo"
# Set OPENAI_API_KEY environment variable
```

**Claude**:
```ruby
config.llm_provider = :claude  
config.model_name = "claude-3-sonnet-20240229"
# Set ANTHROPIC_API_KEY environment variable
```

**Gemini**:
```ruby
config.llm_provider = :gemini
config.model_name = "gemini-pro"  
# Set GOOGLE_API_KEY environment variable
```

## Development & Testing

### Running Tests

```bash
# Run all tests with mocked responses (fast)
bundle exec cucumber

# Run with live API calls (requires API key)
BOTRYTIS_LIVE_API=true bundle exec cucumber

# Run RSpec unit tests  
bundle exec rspec
```

### Understanding the Output

When semantic matching occurs, you'll see a summary at the end:

```bash
🎯 Botrytis Semantic Matching Summary: 10 fuzzy matches found
```

This tells you how many steps were matched semantically vs. exactly.

### Cache Management

Botrytis caches LLM responses to improve performance:

```bash
# Clear cache
rm -rf .botrytis_cache

# Disable caching for development
Botrytis.configure do |config|
  config.cache_enabled = false
end
```

## How It Works

1. **Step Execution**: When Cucumber can't find an exact step match, Botrytis intervenes
2. **LLM Query**: The step text and available step patterns are sent to your configured LLM
3. **Semantic Analysis**: The LLM analyzes semantic similarity and extracts parameters
4. **Confidence Check**: Only matches above the confidence threshold are used
5. **Execution**: The matched step definition runs with extracted parameters
6. **Caching**: Results are cached to avoid repeated API calls

## Requirements

- Ruby 3.1.0 or higher
- Cucumber 9.0 or higher  
- Sublayer 0.2.8 or higher
- API key for your chosen LLM provider

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sublayerapp/botrytis.

### Development Setup

```bash
git clone https://github.com/sublayerapp/botrytis.git
cd botrytis
bundle install

# Run tests
bundle exec rake spec
bundle exec cucumber

# Build gem
bundle exec rake build
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Why "Botrytis"?

Botrytis is a genus of fungi known for being both beneficial and parasitic - much like how this gem helps your tests pass by being a little "fuzzy" with step matching! 🍄