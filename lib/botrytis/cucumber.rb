require 'cucumber'
require 'botrytis'

Cucumber::Cli::Main.class_eval do
  alias_method :original_execute!, :execute!

  def execute!(args)
    args.push('--format', 'Botrytis::Formatter')
    original_execute!(args)
  end
end
