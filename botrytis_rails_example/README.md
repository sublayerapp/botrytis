# Botrytis Rails Demo

This is a demonstration Rails application showcasing **Botrytis** - an LLM-powered semantic matching gem for Cucumber steps.

## What This Demo Shows

This app demonstrates how Botrytis allows your team to write Cucumber scenarios in **natural language** without worrying about exact step definition matches.

### Example: Different Ways to Say the Same Thing

Instead of requiring everyone to use the exact same wording:

```gherkin
# ❌ Without Botrytis - these would all fail:
Given the user has authenticated successfully
Given the user has signed in to their account  
When they browse to the products page
When they navigate to the products page
When they press the "Add to Cart" button
When they tap the "Checkout" button
Then they should view a confirmation message
```

With Botrytis, all these **semantically similar steps match** your existing step definitions automatically! ✨

## Features Demonstrated

- **Authentication variations**: "logged in", "authenticated", "signed in"
- **Navigation synonyms**: "visit", "go to", "browse to", "navigate to"  
- **Action variations**: "click", "press", "tap", "hit"
- **Assertion synonyms**: "see", "view", "find", "observe"
- **Parameter extraction**: Works seamlessly with semantic matches

## Quick Start

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Setup database**:
   ```bash
   rails db:create db:migrate db:seed
   ```

3. **Run the Cucumber tests** (requires OpenAI API key):
   ```bash
   # Set your OpenAI API key
   export OPENAI_API_KEY=your_key_here
   
   # Run the demo
   bundle exec cucumber
   ```

4. **See the magic** ✨ - Watch as semantic matches are found and the summary shows:
   ```
   🎯 Botrytis Semantic Matching Summary: 11 fuzzy matches found
   
   6 scenarios (6 passed)
   37 steps (37 passed)
   ```

## What You'll See

The demo showcases **11 semantic matches** across different scenarios:

- **"authenticated successfully"** → matches **"logged in to their account"**
- **"go to the products page"** → matches **"visit the products page"**  
- **"browse to the products page"** → matches **"visit the products page"**
- **"signed in to their account"** → matches **"logged in to their account"**
- **"choose the ... product"** → matches **"select the ... product"**
- **"press the ... button"** → matches **"click the ... button"**
- **"navigate to the products page"** → matches **"visit the products page"**
- **"tap the ... button"** → matches **"click the ... button"**
- **"pick the ... product"** → matches **"select the ... product"**
- **"hit the ... button"** → matches **"click the ... button"**  
- **"view a confirmation message"** → matches **"see a confirmation message"**

## File Structure

### Key Files:
- **`features/semantic_ecommerce.feature`** - Scenarios using natural language variations
- **`features/step_definitions/ecommerce_steps.rb`** - Step definitions with exact patterns  
- **`features/support/env.rb`** - Botrytis configuration

### Scenarios Include:
1. **Authentication variations** - Different ways to say "login"
2. **Navigation synonyms** - Various ways to navigate pages
3. **Button interactions** - Different action verbs for clicking
4. **Shopping flow** - Complete e-commerce journey with mixed language
5. **Checkout process** - Natural language purchase flow

## How It Works

1. **Exact matches work normally** - No change to existing step definitions
2. **When no exact match found** - Botrytis asks the LLM to find semantic matches
3. **Confidence-based matching** - Only matches above threshold (0.7) are used
4. **Parameter extraction** - Parameters are extracted from semantically matched text
5. **Clean display** - Step text shows naturally without garbled artifacts

## Example Output

```bash
Feature: Semantic E-commerce Flow

  Scenario: Natural language for user authentication  
    Given the user has authenticated successfully      # Semantic match ✨
    When they go to the products page                  # Semantic match ✨
    Then they should see the products list             # Exact match

1 scenario (1 passed)
3 steps (3 steps)

🎯 Botrytis Semantic Matching Summary: 2 fuzzy matches found
```

## Benefits for Teams

- **Product managers** can write scenarios in natural language
- **Developers** don't need to maintain exhaustive step definitions  
- **QA engineers** can focus on test logic rather than exact wording
- **Documentation** reads more naturally for stakeholders
- **Onboarding** is faster - new team members write tests immediately

## Configuration

The demo uses these Botrytis settings in `features/support/env.rb`:

```ruby
Botrytis.configure do |config|
  config.llm_provider = :openai     # Could be :claude or :gemini  
  config.model_name = "gpt-4o"      # The AI model to use
  config.confidence_threshold = 0.7  # How confident the match must be
  config.cache_enabled = false      # Disabled for consistent demo results
end
```

## Real-World Usage

This demo shows a simple e-commerce flow, but Botrytis works with any domain:

- **Financial apps**: "transfer money" vs "send payment" vs "make transaction"
- **Healthcare**: "schedule appointment" vs "book visit" vs "reserve slot"  
- **Social platforms**: "post message" vs "share update" vs "publish content"

The semantic matching makes your BDD tests more **human-friendly** while maintaining the **reliability** of automated testing.

---

**Try it yourself!** Modify the feature files to use your own natural language and see Botrytis find the semantic matches automatically. 🚀
