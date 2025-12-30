# Content Ordering System Design

## Overview

This document describes the design for a configurable content ordering system that determines the sequence in which content items are displayed on screen fields.

## Problem Statement

Currently, `Frontend::ContentController` returns content in an undefined order—simply flattening all active content from subscribed feeds. This provides no control over:

- **Prioritization**: Emergency or important content should appear first
- **Distribution**: Content from multiple feeds should be balanced or weighted
- **Variety**: Consecutive items from the same feed may be undesirable

The legacy Concerto 2 system solved this with "shufflers" (`WeightedShuffle`, `StrictPriorityShuffle`), but the implementation was tightly coupled and difficult to extend.

## Goals

1. **Configurable**: Screen managers can choose an ordering strategy per field
2. **Extensible**: New strategies can be added without modifying existing code
3. **Simple**: Leverage Rails conventions; avoid over-engineering
4. **Testable**: Each strategy is independently testable

## Non-Goals

- Real-time content reordering (ordering happens at content fetch time)
- Complex playlist scheduling (time-based rules beyond start/end times)
- Per-content-item priority (priority is at the subscription level)

## Proposed Design

### Architecture

Use the **Strategy pattern** implemented via Plain Old Ruby Objects (POROs) in `app/services/content_orderers/`. Each orderer is a callable class that takes content with subscription metadata and returns ordered content.

```
┌─────────────────────────────────────────────────────────────────┐
│                  Frontend::ContentController                     │
│                                                                  │
│  1. Load subscriptions for screen/field                         │
│  2. Gather content with subscription metadata                    │
│  3. Look up ordering strategy from FieldConfig                  │
│  4. Instantiate orderer and call with content                   │
│  5. Filter by position compatibility                            │
│  6. Return ordered content                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ContentOrderers::Base                         │
│                                                                  │
│  #call(content_items) → Array<Content>                          │
└─────────────────────────────────────────────────────────────────┘
           ▲                  ▲                    ▲
           │                  │                    │
    ┌──────┴──────┐   ┌───────┴───────┐   ┌───────┴───────┐
    │   Random    │   │   Weighted    │   │StrictPriority │
    └─────────────┘   └───────────────┘   └───────────────┘
```

### Data Model Changes

#### 1. Add `weight` to Subscriptions

Subscriptions need a weight to support weighted ordering strategies.

```ruby
# Migration
class AddWeightToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :weight, :integer, default: 5, null: false
  end
end
```

```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  validates :weight, numericality: { in: 1..10 }
end
```

#### 2. Add `ordering_strategy` to FieldConfig

Store the strategy choice per screen/field combination.

```ruby
# Migration
class AddOrderingStrategyToFieldConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :field_configs, :ordering_strategy, :string, default: "random"
  end
end
```

```ruby
# app/models/field_config.rb
class FieldConfig < ApplicationRecord
  validates :ordering_strategy, inclusion: { in: ContentOrderers::STRATEGIES.keys }, allow_blank: true
end
```

This references `ContentOrderers::STRATEGIES` as the single source of truth, so adding a new orderer only requires updating the registry.

**Note:** The database default is "random" to provide a safe fallback when configuration is missing or incomplete. However, the admin UI defaults to "weighted" when creating new configurations to encourage proper subscription weight setup.

### Service Objects

#### Base Orderer

```ruby
# app/services/content_orderers/base.rb
module ContentOrderers
  class Base
    # @param content_items [Array<Hash>] Array of { content:, subscription: } hashes
    # @return [Array<Content>] Ordered content items
    def call(content_items)
      content_items.map { |item| item[:content] }
    end
  end
end
```

#### Random Orderer (Default)

Shuffles content randomly. Simple and fair.

```ruby
# app/services/content_orderers/random.rb
module ContentOrderers
  class Random < Base
    def call(content_items)
      content_items.shuffle.map { |item| item[:content] }
    end
  end
end
```

#### Weighted Orderer

Duplicates content based on subscription weight, then shuffles. Higher-weighted subscriptions appear more frequently.

```ruby
# app/services/content_orderers/weighted.rb
module ContentOrderers
  class Weighted < Base
    def call(content_items)
      weighted = content_items.flat_map do |item|
        Array.new(item[:subscription].weight, item[:content])
      end

      remove_consecutive_duplicates(weighted.shuffle)
    end

    private

    def remove_consecutive_duplicates(items)
      items.chunk_while { |a, b| a.id == b.id }.map(&:first)
    end
  end
end
```

#### Strict Priority Orderer

Only shows content from the highest-weighted subscription(s). Emergency broadcasts use case.

```ruby
# app/services/content_orderers/strict_priority.rb
module ContentOrderers
  class StrictPriority < Base
    def call(content_items)
      return [] if content_items.empty?

      max_weight = content_items.map { |item| item[:subscription].weight }.max

      content_items
        .select { |item| item[:subscription].weight == max_weight }
        .shuffle
        .map { |item| item[:content] }
    end
  end
end
```

### Registry

A simple registry maps strategy names to classes. This serves as the single source of truth for available strategies:

```ruby
# app/services/content_orderers.rb
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
```

### Controller Integration

```ruby
# app/controllers/frontend/content_controller.rb
class Frontend::ContentController < Frontend::ApplicationController
  def index
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
    @position = Position.find(params[:position_id])

    @content = fetch_pinned_content || fetch_subscription_content

    render json: @content
  end

  private

  def field_config
    @field_config ||= FieldConfig.find_by(screen: @screen, field: @field)
  end

  def fetch_pinned_content
    return nil unless field_config&.pinned_content_id

    pinned = Content.active.find_by(id: field_config.pinned_content_id)
    [pinned] if pinned
  end

  def fetch_subscription_content
    subscriptions = @screen.subscriptions.where(field_id: @field.id).includes(:feed)

    # Build content items with subscription metadata
    content_items = subscriptions.flat_map do |subscription|
      subscription.contents.active.filter_map do |content|
        { content: content, subscription: subscription } if content.should_render_in?(@position)
      end
    end

    # Apply ordering strategy (defaults to "random" if no config or blank strategy)
    strategy = field_config&.ordering_strategy.presence || "random"
    orderer = ContentOrderers.for(strategy)
    orderer.call(content_items)
  end
end
```

## UI Considerations

### Authorization

Ordering strategy and subscription weights follow existing screen permissions: any group member who owns the screen can modify these settings.

### Screen Manager Interface

Add an "Advanced Settings" or "Field Settings" section to the screen edit page where managers can:

1. Select an ordering strategy from a dropdown
2. View/edit subscription weights (perhaps inline on the subscriptions list)

The UI should explain each strategy:

| Strategy | Description |
|----------|-------------|
| Random | Content appears in random order |
| Weighted | Higher-weighted feeds appear more often (recommended) |
| Strict Priority | Only shows content from highest-priority feed |

**UI Default:** When creating new field configurations, the dropdown defaults to "Weighted" and displays it as "Weighted (Default)" to encourage admins to properly configure subscription weights.

### Subscription Weight UI

When editing subscriptions, show a dropdown with 5 levels:

| Label | Stored Value |
|-------|--------------|
| Low | 2 |
| Medium-Low | 4 |
| Normal | 5 (default) |
| Medium-High | 6 |
| High | 8 |

Default is "Normal" (5). Weights are only meaningful when using Weighted or Strict Priority strategies.

## Migration Path

### Phase 1: Infrastructure

1. Add migrations for `weight` and `ordering_strategy` columns
2. Create `ContentOrderers` service objects
3. Update controller to use orderers
4. Default behavior remains "random" (similar to current behavior)

### Phase 2: UI

1. Add strategy selector to screen/field config UI
2. Add weight controls to subscription management

### Phase 3: Enhancements (Future)

- Additional strategies (round-robin, time-weighted, etc.)
- Strategy-specific options stored in FieldConfig JSON column
- Analytics on content display frequency

## Testing Strategy

### Unit Tests

Each orderer should be tested in isolation:

```ruby
# test/services/content_orderers/weighted_test.rb
class ContentOrderers::WeightedTest < ActiveSupport::TestCase
  test "duplicates content based on weight" do
    content1 = contents(:one)
    content2 = contents(:two)
    sub_high = Subscription.new(weight: 3)
    sub_low = Subscription.new(weight: 1)

    items = [
      { content: content1, subscription: sub_high },
      { content: content2, subscription: sub_low }
    ]

    orderer = ContentOrderers::Weighted.new
    # Run multiple times to verify distribution
    results = 100.times.map { orderer.call(items) }

    # content1 should appear ~3x as often as content2
    content1_count = results.flatten.count { |c| c == content1 }
    content2_count = results.flatten.count { |c| c == content2 }

    assert_in_delta 3.0, content1_count.to_f / content2_count, 0.5
  end
end
```

### Integration Tests

Test the full controller flow:

```ruby
# test/controllers/frontend/content_controller_test.rb
test "uses weighted ordering when configured" do
  field_config = FieldConfig.create!(
    screen: @screen,
    field: @field,
    ordering_strategy: "weighted"
  )

  get frontend_screen_field_position_content_index_path(
    screen_id: @screen.id,
    field_id: @field.id,
    position_id: @position.id
  )

  assert_response :success
  # Verify content is returned (ordering is non-deterministic)
  assert JSON.parse(response.body).any?
end
```

## Design Decisions

1. **Weight lives on Subscription**: Screen managers weight feeds relative to each other for a given field, not individual content items.

2. **No strategy-specific configuration**: To support long-term maintainability, strategies are self-contained with no additional options.

3. **Fallback strategy is "random", UI default is "weighted"**:
   - **Database/Code Fallback:** The database default and code fallbacks use "random" as a safe default when configuration is missing, incomplete, or invalid. This ensures graceful degradation when subscription weights aren't properly configured.
   - **Admin UI Default:** The admin interface defaults to "weighted" when creating new field configurations and displays it as "Weighted (Default)" to encourage best practices and proper subscription weight setup.
   - **Rationale:** Weighted ordering requires properly configured subscription weights. When falling back to a default (because no FieldConfig exists or strategy is blank), those weights may not be available or meaningful, making "random" the safer choice. However, when admins are actively configuring a field, we encourage them to use weighted ordering.

4. **Pure random ordering**: No seeded randomness; content order varies on each request.

5. **Lazy FieldConfig creation**: Records are only created when a user sets non-default configuration (pinned content or ordering strategy), avoiding empty records.

6. **Weight range 1-10**: Stored as integer 1-10 for flexibility; UI can present simplified options (e.g., 5 levels: Low/Medium-Low/Medium/Medium-High/High mapped to 2/4/5/6/8).

## File Structure

```
app/
├── controllers/
│   └── frontend/
│       └── content_controller.rb  # Updated
├── models/
│   ├── field_config.rb            # Updated
│   └── subscription.rb            # Updated
└── services/
    ├── content_orderers.rb          # Registry (single source of truth)
    └── content_orderers/
        ├── base.rb
        ├── random.rb
        ├── strict_priority.rb
        └── weighted.rb

db/migrate/
├── XXXXXX_add_weight_to_subscriptions.rb
└── XXXXXX_add_ordering_strategy_to_field_configs.rb

test/
└── services/
    └── content_orderers/
        ├── random_test.rb
        ├── strict_priority_test.rb
        └── weighted_test.rb
```

## References

- [Concerto 2 WeightedShuffle](~/dev/concerto/lib/weighted_shuffle.rb)
- [Concerto 2 StrictPriorityShuffle](~/dev/concerto/lib/strict_priority_shuffle.rb)
- [Rails Service Objects](https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial)
