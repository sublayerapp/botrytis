require 'sublayer'

module Botrytis
  class SemanticMatchGenerator < Sublayer::Generators::Base
    llm_output_adapter type: :named_strings,
      name: "step_match_result",
      description: "Results of semantic matching for a cucumber step",
      attributes: [
        { name: "match_found", description: "
      ]
  end
end
