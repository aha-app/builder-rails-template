# Testing Guide

This project uses RSpec with Inertia testing helpers. Add `:inertia` flag to request specs for Inertia matchers.

## Testing Strategy

- **Models**: `spec/models/item_spec.rb` - validate presence, length, associations
- **Controllers**: `spec/requests/items_spec.rb` - test all CRUD actions (happy path + validation failures)

## Model Specs

Test validations, associations, and custom methods:

```ruby
# spec/models/item_spec.rb
require 'rails_helper'

RSpec.describe Item do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:comments) }
  end
end
```

## Request Specs (Controllers)

### Basic Pattern

```ruby
# spec/requests/items_spec.rb
require 'rails_helper'

RSpec.describe "/items", inertia: true do
  let(:user) { create(:user) }
  let(:valid_attributes) { { name: "Test Item", description: "Description" } }
  let(:invalid_attributes) { { name: "" } }

  before { sign_in(user) } # if authentication required

  describe "GET /index" do
    it "renders component with props" do
      item = Item.create!(valid_attributes)
      get items_path

      expect(inertia).to render_component("items/index")
      expect(inertia).to include_props(items: [])
      expect(inertia.props[:items]).to be_an(Array)
      expect(inertia.props[:items].first['name']).to eq("Test Item")
    end
  end

  describe "GET /show" do
    it "renders component with item" do
      item = Item.create!(valid_attributes)
      get item_path(item)

      expect(inertia).to render_component("items/show")
      expect(inertia.props[:item]['id']).to eq(item.id)
    end
  end

  describe "GET /new" do
    it "renders new form component" do
      get new_item_path

      expect(inertia).to render_component("items/new")
      expect(inertia.props[:item]).to be_present
    end
  end

  describe "GET /edit" do
    it "renders edit form component" do
      item = Item.create!(valid_attributes)
      get edit_item_path(item)

      expect(inertia).to render_component("items/edit")
      expect(inertia.props[:item]['id']).to eq(item.id)
    end
  end

  describe "POST /items" do
    context "with valid params" do
      it "creates item and redirects" do
        expect {
          post items_path, params: { item: valid_attributes }
        }.to change(Item, :count).by(1)

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(items_path)
      end
    end

    context "with invalid params" do
      it "renders form with errors" do
        post items_path, params: { item: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_content)
        expect(inertia).to render_component("items/new")
        expect(inertia.props[:errors][:name]).to be_present
      end
    end
  end

  describe "PATCH /items/:id" do
    let(:item) { Item.create!(valid_attributes) }
    let(:new_attributes) { { name: "Updated Name" } }

    context "with valid params" do
      it "updates item and redirects" do
        patch item_path(item), params: { item: new_attributes }

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(items_path)
        expect(item.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      it "renders form with errors" do
        patch item_path(item), params: { item: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_content)
        expect(inertia).to render_component("items/edit")
        expect(inertia.props[:errors][:name]).to be_present
      end
    end
  end

  describe "DELETE /items/:id" do
    it "destroys item and redirects" do
      item = Item.create!(valid_attributes)

      expect {
        delete item_path(item)
      }.to change(Item, :count).by(-1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(items_path)
    end
  end
end
```

## Inertia Matchers

Available matchers for testing Inertia responses:

| Matcher | Usage | Description |
|---------|-------|-------------|
| `render_component` | `expect(inertia).to render_component("items/index")` | Asserts rendered component name |
| `include_props` | `expect(inertia).to include_props(items: [])` | Asserts props include specified keys |
| `have_exact_props` | `expect(inertia).to have_exact_props(items: [])` | Asserts props match exactly |
| `include_view_data` | `expect(inertia).to include_view_data(auth: anything)` | Asserts view_data includes keys |
| `have_exact_view_data` | `expect(inertia).to have_exact_view_data(...)` | Asserts view_data matches exactly |

## HTTP Status Codes

Use the correct status codes for Inertia responses:

- **Success (redirect)**: `:see_other` (303)
- **Validation error**: `:unprocessable_content` (422)
- **Not found**: `:not_found` (404)

**Important:** Use `:unprocessable_content` (not `:unprocessable_entity`) - the latter is deprecated in Rack.

```ruby
# ✅ CORRECT
expect(response).to have_http_status(:unprocessable_content)

# ❌ WRONG
expect(response).to have_http_status(:unprocessable_entity)
```

## Inertia Props and Keys

When using `.as_json` to serialize models, the resulting props have **string keys**, not symbol keys.

```ruby
# Controller
inertia_share auth: -> {
  {
    user: current_user&.as_json(only: %i[id email_address])
  }
}

# ✅ CORRECT - Access with string keys
expect(inertia.props[:auth][:user]['email_address']).to eq('test@example.com')

# ❌ WRONG - Symbol key won't work for serialized attributes
expect(inertia.props[:auth][:user][:email_address]).to eq('test@example.com')
```

### Key Access Pattern

- **Top-level `inertia_share` keys**: symbols (`:auth`, `:flash`)
- **Nested keys from `.as_json()`**: strings (`'email_address'`, `'id'`)
- **Manually built hashes**: symbols throughout

### Alternative: Manual Hash Building

For symbol keys throughout, build hashes manually:

```ruby
inertia_share auth: -> {
  {
    user: current_user ? {
      id: current_user.id,
      email_address: current_user.email_address
    } : nil
  }
}

# Now you can use symbol keys
expect(inertia.props[:auth][:user][:email_address]).to eq('test@example.com')
```

## Props vs View Data

All `inertia_share` data goes into **props**, accessible to your React components:

```ruby
# Controller
inertia_share flash: -> { flash.to_hash },
              auth: -> { { user: current_user } }

# ✅ CORRECT - Both are props
expect(inertia.props[:flash][:notice]).to eq('Success!')
expect(inertia.props[:auth][:user]).to be_present

# ❌ WRONG - inertia_share doesn't create view_data
expect(inertia.view_data[:auth]).to be_present
```

`view_data` is only used when explicitly passed and is for Rails layout, not React:

```ruby
render inertia: 'items/show',
       props: { item: @item },
       view_data: { meta_title: 'Details' }  # For ERB layout only

# In tests
expect(inertia).to include_view_data(meta_title: 'Details')
```

## Testing Shared Data

Test that shared data (from `inertia_share`) is available on all requests:

```ruby
describe "shared data" do
  it "includes auth data on all pages" do
    get items_path

    expect(inertia.props[:auth]).to be_present
    expect(inertia.props[:flash]).to eq({})
  end

  it "includes flash messages" do
    get items_path, flash: { notice: 'Success!' }

    expect(inertia.props[:flash][:notice]).to eq('Success!')
  end
end
```

## Testing Signed Cookies

Use `signed_cookies` helper to test signed cookie values:

```ruby
# spec/support/signed_cookies_helper.rb
module SignedCookiesHelper
  def signed_cookies
    request.cookie_jar.signed
  end
end

RSpec.configure do |config|
  config.include SignedCookiesHelper, type: :request
end

# In your specs
describe "POST /session" do
  it "sets session cookie" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: 'secret' }

    expect(signed_cookies[:session_id]).to eq(user.sessions.last.id)
  end
end
```

## Testing File Uploads

```ruby
describe "POST /items with file upload" do
  it "uploads file successfully" do
    file = fixture_file_upload('test.pdf', 'application/pdf')

    post items_path, params: {
      item: { name: "Test", attachment: file }
    }

    expect(response).to have_http_status(:see_other)
    expect(Item.last.attachment).to be_attached
  end
end
```

## Factory Bot Setup

Use FactoryBot for test data:

```ruby
# spec/factories/items.rb
FactoryBot.define do
  factory :item do
    name { "Test Item" }
    description { "Test description" }
  end
end

# In specs
let(:item) { create(:item) }
let(:items) { create_list(:item, 3) }
```

## Common Testing Patterns

### Testing Authorization

```ruby
describe "GET /items/:id" do
  context "when user is authorized" do
    it "renders the item" do
      item = create(:item, user: user)
      get item_path(item)

      expect(inertia).to render_component("items/show")
    end
  end

  context "when user is not authorized" do
    it "redirects or returns forbidden" do
      other_user_item = create(:item)
      get item_path(other_user_item)

      expect(response).to have_http_status(:forbidden)
      # or expect(response).to redirect_to(root_path)
    end
  end
end
```

### Testing with Authentication

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.include SessionHelper, type: :request
end

# spec/support/session_helper.rb
module SessionHelper
  def sign_in(user)
    post session_path, params: {
      email_address: user.email_address,
      password: 'password'
    }
  end
end

# In specs
before { sign_in(user) }
```
