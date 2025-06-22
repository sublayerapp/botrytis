# Future Test Ideas for Botrytis

## Parameter Translation & Extraction Testing

These are advanced test scenarios for future development that go beyond the basic semantic matching demonstrated in the blog post.

### Complex Parameter Extraction
Test the ability to extract parameters from semantically similar but structurally different steps.

**Example:**
- **Defined step**: `When I (buy|sell) (\d+) (.*) for \$(\d+\.\d+)`
- **Test cases**:
  - "When I purchase 3 bananas for $2.50" → should match with params `["purchase", "3", "bananas", "2.50"]`
  - "When I acquire 5 oranges for $10.00" → should match with params `["acquire", "5", "oranges", "10.00"]`
  - "When I sell 2 cars for $15000.00" → should match with params `["sell", "2", "cars", "15000.00"]`

### Text-to-Number Parameter Conversion
Test semantic understanding of different number representations.

**Example:**
- **Defined step**: `Given I have (\d+) apples`
- **Test cases**:
  - "Given I have five apples" → should extract `"5"`
  - "Given I possess a dozen apples" → should extract `"12"`
  - "Given I own several apples" → should handle ambiguous quantities

### Date/Time Parameter Semantic Matching
Test interpretation of different time expressions.

**Example:**
- **Defined step**: `When I schedule a meeting for (\d{4}-\d{2}-\d{2})`
- **Test cases**:
  - "When I schedule a meeting for tomorrow" → should convert to actual date
  - "When I schedule a meeting for next Friday" → should convert to appropriate date
  - "When I schedule a meeting for Christmas" → should handle holiday conversion

### Multiple Parameter Reordering
Test ability to match steps where parameters appear in different orders.

**Example:**
- **Defined step**: `Given (\w+) has (\d+) (.*) in their (\w+)`
- **Test cases**:
  - "Given Alice has 5 books in their backpack" → `["Alice", "5", "books", "backpack"]`  
  - "Given there are 3 pencils in Bob's drawer" → should reorder to `["Bob", "3", "pencils", "drawer"]`

## Advanced Confidence Testing

### Confidence Threshold Edge Cases
Test behavior at various confidence levels to validate threshold settings.

- Steps that should match at 0.9+ confidence
- Steps that should match at 0.7-0.8 confidence  
- Steps that should be rejected below 0.7 confidence
- Borderline cases that test threshold boundaries

### Ambiguous Step Resolution
Test handling when multiple step definitions could match with similar confidence.

**Example:**
- **Defined steps**: 
  - `When I click the save button`
  - `When I click the submit button`
- **Ambiguous input**: "When I click the confirm button"
- **Expected behavior**: Either pick highest confidence match or request clarification

## Performance & Scale Testing

### Large Step Definition Sets
Test performance with hundreds of step definitions to ensure semantic matching scales.

### Caching Effectiveness
Validate that caching improves performance for repeated semantic matches.

### LLM Provider Comparison
Test semantic matching quality across different LLM providers (OpenAI, Anthropic, local models).

## Error Handling & Resilience

### LLM Service Failures
Test graceful degradation when LLM service is unavailable:
- Should fall back to exact matching
- Should provide helpful error messages
- Should not crash the test suite

### Malformed LLM Responses
Test handling of unexpected LLM response formats:
- Invalid JSON responses
- Missing required fields
- Confidence scores outside 0.0-1.0 range

### Network Timeout Scenarios  
Test behavior under poor network conditions:
- Slow LLM responses
- Connection timeouts
- Retry logic validation

## Integration with BDD Tools

### Multiple Cucumber Versions
Test compatibility across different versions of Cucumber gem.

### Other BDD Frameworks
Explore integration with:
- RSpec feature specs
- Turnip
- Spinach

### IDE Integration
Test semantic matching in development environments:
- Step definition discovery in IDEs
- Autocomplete with semantic suggestions
- Real-time matching feedback

## Real-World Scenario Testing

### Business Domain Vocabularies
Test semantic matching within specific business contexts:
- E-commerce scenarios (buy/purchase/order)
- Financial scenarios (pay/transfer/deposit)  
- Healthcare scenarios (diagnose/treat/prescribe)

### Multi-language Step Definitions
Test semantic matching across different natural languages:
- English variations
- Formal vs informal language
- Technical vs business terminology

## Security & Privacy Considerations

### Sensitive Data in Steps
Ensure no sensitive information is sent to LLM providers:
- Test with steps containing mock credentials
- Validate data sanitization
- Test privacy-preserving modes

### LLM Provider Data Retention
Understand and test implications of different LLM providers' data policies.

## Conclusion

These advanced test scenarios will help ensure Botrytis becomes a robust, production-ready tool for semantic step matching. They build upon the basic functionality demonstrated in the blog post examples.