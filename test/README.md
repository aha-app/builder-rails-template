# Testing Guide

This project uses **Minitest** (not RSpec) and frontend tests use **Vitest** with React Testing Library. Place test files as `*.test.tsx` alongside components in `app/frontend/`.

## Testing Strategy

- **Only write unit tests** (model tests) for business logic
- **Exception: Write controller tests for non-Inertia responses:**
  - Export/download actions that stream files
  - API endpoints that return JSON
  - Any action that uses `send_data`, `send_file`, or custom headers
  - Actions that don't render Inertia or redirect
- Delete controller or integration test files if they are generated and are not needed.
- **Always use fixtures** over factories.
- Test files go in `test/models/`.

### Why the Exception?

For standard Inertia actions, controller tests provide minimal value because they test plumbing. But for exports/downloads:

- The HTTP response structure IS the feature
- Binary data streaming can't be verified visually
- Content-Type, Content-Disposition headers must be correct
- File downloads aren't reliably testable in browser automation
- Integration between params → service → response needs validation

**Put logic in models and test it there.** Controllers should be thin—just coordination between models and Inertia responses.

## Model Tests

Test validations, associations, scopes, and custom methods:

```ruby
# test/models/item_test.rb
require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "validates presence of name" do
    item = Item.new(name: nil)
    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end

  test "validates length of name" do
    item = Item.new(name: "a" * 256)
    assert_not item.valid?
    assert_includes item.errors[:name], "is too long (maximum is 255 characters)"
  end

  test "validates uniqueness of email case-insensitively" do
    existing = items(:one)
    duplicate = Item.new(email_address: existing.email_address.upcase)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end
end
```

## Fixtures

Use fixtures for test data in `test/fixtures/`:

```yaml
# test/fixtures/items.yml
one:
  name: First Item
  description: A test item

two:
  name: Second Item
  description: Another test item
```

Access in tests:

```ruby
test "something with fixture" do
  item = items(:one)
  assert_equal "First Item", item.name
end
```

## Testing Custom Methods

```ruby
class ItemTest < ActiveSupport::TestCase
  test "#display_name returns formatted name" do
    item = Item.new(name: "test item")
    assert_equal "Test Item", item.display_name
  end

  test "#expired? returns true when past expiration" do
    item = Item.new(expires_at: 1.day.ago)
    assert item.expired?
  end

  test "#expired? returns false when before expiration" do
    item = Item.new(expires_at: 1.day.from_now)
    assert_not item.expired?
  end
end
```

## Testing Scopes

```ruby
class ItemTest < ActiveSupport::TestCase
  test ".active returns only active items" do
    active = items(:active_item)
    inactive = items(:inactive_item)

    results = Item.active
    assert_includes results, active
    assert_not_includes results, inactive
  end

  test ".recent returns items ordered by created_at desc" do
    results = Item.recent
    assert_equal results, results.sort_by(&:created_at).reverse
  end
end
```

## Testing Callbacks

```ruby
class ItemTest < ActiveSupport::TestCase
  test "normalizes name before save" do
    item = Item.create!(name: "  spaced out  ")
    assert_equal "spaced out", item.name
  end

  test "generates slug from name on create" do
    item = Item.create!(name: "My Great Item")
    assert_equal "my-great-item", item.slug
  end
end
```

## Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/item_test.rb

# Run specific test by line number
bin/rails test test/models/item_test.rb:10

# Run with verbose output
bin/rails test -v
```
