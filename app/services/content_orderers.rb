# frozen_string_literal: true

module ContentOrderers
  STRATEGIES = {
    "random" => ContentOrderers::Random,
    "weighted" => ContentOrderers::Weighted,
    "strict_priority" => ContentOrderers::StrictPriority
  }.freeze

  def self.for(strategy_name)
    STRATEGIES.fetch(strategy_name, STRATEGIES["random"]).new
  end
end
