# Builder Application

This is a Rails 8 application template using Inertia.js with React. It is a greenfield Rails app using Rspec with no existing models/controllers to reference.

## Stack

Rails 8.1 + Inertia.js + React 19 + TypeScript + Vite. Uses shadcn/ui components, Tailwind CSS v4, and JS-Routes for type-safe routing (`import { rootPath } from "@/routes"`). Database-backed infrastructure: Solid Cache/Queue/Cable.

### General Rules

- Early development, no users. No backwards compatibility concerns. Do things RIGHT: clean, organized, zero tech debt. Never create compatibility shims.
- WE NEVER WANT WORKAROUNDS, we always want FULL implementations that are long term sustainable for many >1000 users. so dont come up with half baked solutions

## Frontend Structure

- **Entry**: `app/frontend/entrypoints/inertia.ts`
- **Styles**: `app/frontend/entrypoints/application.css`
- **Pages**: `app/frontend/pages/` (Inertia page components)
- **Components**: `app/frontend/components/` (shadcn/ui components)
- **Types**: `app/frontend/types/`

## Commands

| Command                                | Purpose                                                 |
| -------------------------------------- | ------------------------------------------------------- |
| `./bin/ci`                             | Run all checks (RSpec, Rubocop, TS/JS lint, type check) |
| `bundle exec rspec`                    | Run RSpec test suite                                    |
| `./bin/rails generate model/migration` | Generate models/migrations                              |
| `./bin/rails js:routes`                | Generate TypeScript route definitions                   |
| `npm lint:fix`                         | Fix JS/TS lint issues                                   |
| `npm format:fix`                       | Format code with Prettier                               |

- `./bin/ci` is the main command to run for tests, linting, and type checking.

## Inertia.js Essentials

### Navigation

- **Standard**: `<Link href="/path">`
- **Programmatic**: `router.visit('/path')` (for callbacks, conditionals)

### Rendering Behavior

**Always use explicit `render inertia:` calls** to avoid security risks from accidentally leaking sensitive data.

```ruby
class ItemsController < InertiaController
  def index
    items = Item.all.as_json(only: %i[id name])
    render inertia: "items/index", props: { items: items }
  end

  def create
    item = Item.new(item_params)
    if item.save
      redirect_to items_path, notice: "Item was successfully created."
    else
      render inertia: "items/new", props: { item: item }.merge(inertia_errors(item)), status: :unprocessable_content
    end
  end
end
```

**Key principle:** Explicitly specify which data to pass as props. This prevents accidentally exposing instance variables like `@current_user`, memoized variables, or internal state to the frontend.

### Shared Data

Add global props via `inertia_share` in `InertiaController`:

```ruby
inertia_share do
  { auth: { user: Current.user&.as_json(only: %i[id email name]) } }
end
```

CSRF tokens and flash messages (`:notice`, `:alert`) are handled automatically.

### Authorization

Pass authorization checks as props (don't rely on server helpers in React):

```ruby
render inertia: 'posts/show', props: {
  post: @post.as_json,
  can_edit: policy(@post).update?
}
```

### Performance

**Deferred props:** `stats: InertiaRails.defer { expensive_calculation }` loads after initial render. Group with `group: 'name'` for parallel fetching.

**Lazy loading:** Remove `{ eager: true }` from `import.meta.glob('../pages/**/*.tsx')` for code splitting (large apps only).

## Forms

**Prefer `<Form>` over `useForm`** - handles 90% of cases.

### Uncontrolled Inputs Pattern

```tsx
import { Form } from "@inertiajs/react"

// ✅ CORRECT: Uncontrolled form with resetOnSuccess
export default () => (
  <Form action="/users" method="post" resetOnSuccess>
    {({ errors, processing }) => (
      <>
        <input name="name" defaultValue="John" />
        {errors.name && <div>{errors.name}</div>}

        <input name="user.skills[]" />
        <input type="file" name="avatar" />

        <button disabled={processing}>Submit</button>
      </>
    )}
  </Form>
)
```

**Key principles:**

- Use `name` attribute (not `value` + `onChange`)
- Use `defaultValue` for initial values
- Use `resetOnSuccess` to clear form after submission
- Access reactive state via slot props: `errors`, `processing`, `isDirty`, `wasSuccessful`
- Automatically handles nested data (`report[description]`), arrays (`tags[]`), file uploads

**When to use `useForm` instead:**

- Programmatic control over form state
- Real-time validation
- Complex field interdependencies

### File Uploads with PUT/PATCH

Use method spoofing (multipart doesn't support PUT/PATCH natively):

```tsx
<Form action="/users/1" method="post">
  <input type="hidden" name="_method" value="put" />
  <input type="file" name="avatar" />
</Form>
```

## Controllers

New Rails controllers should inherit from `InertiaController`:

```ruby
class UsersController < InertiaController
end
```

Use `inertia_errors(model)` helper for validation errors (returns `{ errors: { field: "message" } }`).

## Component Patterns

This guide covers shadcn/ui component patterns and common import mistakes.

### Common Import Mistakes

#### FieldInput Does Not Exist

The shadcn/ui `Field` component does **not** export `FieldInput`. Use `Input` from `@/components/ui/input` instead.

```tsx
// ❌ WRONG - FieldInput doesn't exist
import { Field, FieldLabel, FieldInput } from "@/components/ui/field"

// ✅ CORRECT - Import Input separately
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

// Usage
;<Field>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <Input name="email" type="email" id="email" />
  {errors?.email && <FieldError>{errors.email}</FieldError>}
</Field>
```

#### Available Field Exports

**Field components:**

- `Field` - Wrapper component
- `FieldLabel` - Label for field
- `FieldError` - Error message display
- `FieldDescription` - Help text/description

**Field grouping:**

- `FieldGroup` - Group multiple fields
- `FieldSet` - Fieldset wrapper
- `FieldLegend` - Legend for fieldset
- `FieldContent` - Content wrapper
- `FieldTitle` - Title component
- `FieldSeparator` - Visual separator

**Separate imports needed:**

- `Input` from `@/components/ui/input`
- `Textarea` from `@/components/ui/textarea`
- `Select` from `@/components/ui/select`

### Empty State Pattern

Use `Empty` component with slot-based composition (no direct `title`/`description` props):

```tsx
import {
  Empty,
  EmptyHeader,
  EmptyTitle,
  EmptyDescription,
  EmptyContent,
} from "@/components/ui/empty"
import { Button } from "@/components/ui/button"
import { Link } from "@inertiajs/react"

export default function ItemsIndex({ items }) {
  if (items.length === 0) {
    return (
      <Empty>
        <EmptyHeader>
          <EmptyTitle>No items found</EmptyTitle>
          <EmptyDescription>
            Get started by creating your first item.
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <Link href="/items/new">
            <Button>Create Item</Button>
          </Link>
        </EmptyContent>
      </Empty>
    )
  }

  // ... render items
}
```

### Form Field Patterns

#### Basic Text Input

```tsx
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
;<Field>
  <FieldLabel htmlFor="item_name">Name</FieldLabel>
  <Input name="item[name]" defaultValue={item.name} id="item_name" />
  {errors?.name && <FieldError>{errors.name}</FieldError>}
</Field>
```

### Complete Form Example

```tsx
import { Form } from "@inertiajs/react"
import {
  Field,
  FieldLabel,
  FieldError,
  FieldDescription,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"

type Props = {
  item: {
    name?: string
    description?: string
    price?: number
  }
  errors?: {
    name?: string
    description?: string
    price?: string
  }
}

export default function ItemForm({ item, errors }: Props) {
  return (
    <Form action="/items" method="post" resetOnSuccess>
      {({ processing }) => (
        <div className="space-y-6">
          <Field>
            <FieldLabel htmlFor="item_name">Name</FieldLabel>
            <Input name="item[name]" defaultValue={item.name} id="item_name" />
            {errors?.name && <FieldError>{errors.name}</FieldError>}
          </Field>

          <Field>
            <FieldLabel htmlFor="item_description">Description</FieldLabel>
            <FieldDescription>
              Provide a detailed description of the item
            </FieldDescription>
            <Textarea
              name="item[description]"
              defaultValue={item.description}
              id="item_description"
            />
            {errors?.description && (
              <FieldError>{errors.description}</FieldError>
            )}
          </Field>

          <Field>
            <FieldLabel htmlFor="item_price">Price</FieldLabel>
            <Input
              type="number"
              name="item[price]"
              defaultValue={item.price}
              step="0.01"
              id="item_price"
            />
            {errors?.price && <FieldError>{errors.price}</FieldError>}
          </Field>

          <div className="flex gap-4">
            <Button type="submit" disabled={processing}>
              {processing ? "Saving..." : "Save Item"}
            </Button>
            <Button type="button" variant="outline">
              Cancel
            </Button>
          </div>
        </div>
      )}
    </Form>
  )
}
```

### Form and Card Component Nesting

**IMPORTANT**: Forms must be fully inside or fully outside Card components. Do not split Card structure across Form boundaries.

```tsx
// ❌ WRONG - Form breaks Card component hierarchy
<Card>
  <CardHeader>
    <CardTitle>Create an account</CardTitle>
  </CardHeader>
  <Form action={signupPath()} method="post">
    {({ processing }) => (
      <>
        <CardContent className="space-y-4">
          {/* Form fields */}
        </CardContent>
        <CardFooter>
          <Button type="submit">Submit</Button>
        </CardFooter>
      </>
    )}
  </Form>
</Card>

// ✅ CORRECT - Form inside CardContent
<Card>
  <CardHeader>
    <CardTitle>Create an account</CardTitle>
    <CardDescription>Enter your details to sign up for an account</CardDescription>
  </CardHeader>
  <CardContent>
    <Form action={signupPath()} method="post">
      {({ processing }) => (
        <div className="space-y-4">
          {/* Form fields */}
          <Button type="submit" disabled={processing}>
            {processing ? 'Submitting...' : 'Submit'}
          </Button>
        </div>
      )}
    </Form>
  </CardContent>
</Card>

// ✅ ALSO CORRECT - Form wraps entire Card
<Form action={signupPath()} method="post">
  {({ processing }) => (
    <Card>
      <CardHeader>
        <CardTitle>Create an account</CardTitle>
        <CardDescription>Enter your details to sign up for an account</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Form fields */}
      </CardContent>
      <CardFooter>
        <Button type="submit" disabled={processing}>
          {processing ? 'Submitting...' : 'Submit'}
        </Button>
      </CardFooter>
    </Card>
  )}
</Form>
```

#### Why This Matters

- **Breaking Card's component structure causes styling and semantic issues**
- **Card components expect direct children in a specific order** (Header → Content → Footer)
- **Form's render function creates a new component boundary** that disrupts this hierarchy

**General rule:** Keep component hierarchies intact. If a parent component expects specific children structure (like Card), don't interrupt it with wrapper components like Form.

### Layout Components

#### PersistentLayout

The persistent layout wraps all pages by default.

How to update `PersistentLayout` with header and footer:

```tsx
// PersistentLayout
export default function PersistentLayout({ children }) {
  return (
    <div className="flex min-h-screen flex-col">
      <header className="bg-background border-b">
        <div className="h-16 ... ...">...</div>
      </header>
      <main className="flex flex-1">{children}</main>
      <Toaster richColors />
    </div>
  )
}
```

#### Custom Per-Page Layout

Override the layout for specific pages:

```tsx
import CustomLayout from "@/layouts/custom-layout"

export default function SpecialPage() {
  return <div>{/* page content */}</div>
}

SpecialPage.layout = (page: React.ReactNode) => (
  <CustomLayout>{page}</CustomLayout>
)
```

#### Page Components

**Pages render inside the PersistentLayout's `<main>` element. Never use `min-h-screen` in pages.**

```tsx
// ❌ WRONG - Nested min-h-screen
export default function ItemsIndex() {
  return (
    <div className="min-h-screen p-6">
      {" "}
      {/* Don't do this! */}
      <h1>Items</h1>
    </div>
  )
}

// ✅ CORRECT - Use flex-1 to fill available space
export default function ItemsIndex() {
  return (
    <div className="flex flex-1 flex-col p-6">
      <h1>Items</h1>
    </div>
  )
}

// ✅ CORRECT - Centered content page
export default function SignIn() {
  return (
    <div className="flex flex-1 items-center justify-center p-4">
      <Card>...</Card>
    </div>
  )
}
```

### TypeScript Types

#### Page Props Type

```tsx
type Item = {
  id: number
  name: string
  description: string | null
  created_at: string
}

type Props = {
  item: Item
  errors?: Record<string, string>
}

export default function Show({ item, errors }: Props) {
  // ...
}
```

#### Shared Props (from inertia_share)

```tsx
// Define in types/inertia.d.ts
declare module "@inertiajs/core" {
  interface PageProps {
    auth: {
      user: {
        id: number
        email: string
        name: string
      } | null
    }
    flash: {
      notice?: string
      alert?: string
    }
  }
}

// Access in components
import { usePage } from "@inertiajs/react"

export default function MyComponent() {
  const { auth, flash } = usePage().props

  return (
    <div>
      {auth.user && <p>Hello, {auth.user.name}</p>}
      {flash.notice && <div className="notice">{flash.notice}</div>}
    </div>
  )
}
```

# Standard CRUD Pattern

Follow this pattern when implementing CRUD resources (boards, projects, tasks, etc.) unless explicitly requested otherwise.

## Backend Structure

### 1. Model + Migration

Add model with validations, enforce constraints in DB where practical (`null: false`, etc.)

```ruby
# db/migrate/20240101000000_create_items.rb
class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end

# app/models/item.rb
class Item < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
end
```

### 2. Routes

Use `resources :items` (or set `root "items#index"` if applicable)

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :items
  # or
  root "items#index"
end
```

### 3. Controller

Inherit from `InertiaController`, implement standard actions:

```ruby
class ItemsController < InertiaController
  before_action :set_item, only: %i[show edit update destroy]

  def index
    items = Item.all.as_json(only: %i[id name created_at])
    render inertia: "items/index", props: { items: items }
  end

  def show
    item = @item.as_json(only: %i[id name description created_at])
    render inertia: "items/show", props: { item: item }
  end

  def new
    item = Item.new.as_json(only: %i[name description])
    render inertia: "items/new", props: { item: item }
  end

  def edit
    item = @item.as_json(only: %i[id name description])
    render inertia: "items/edit", props: { item: item }
  end

  def create
    item = Item.new(item_params)
    if item.save
      redirect_to items_path, notice: "Item was successfully created."
    else
      render inertia: "items/new", props: { item: item }.merge(inertia_errors(item)), status: :unprocessable_content
    end
  end

  def update
    if @item.update(item_params)
      redirect_to items_path, notice: "Item was successfully updated."
    else
      render inertia: "items/edit", props: { item: @item }.merge(inertia_errors(@item)), status: :unprocessable_content
    end
  end

  def destroy
    @item.destroy!
    redirect_to items_path, notice: "Item was successfully deleted."
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :description)
  end
end
```

### Key Points

- **Always use explicit `render inertia:`** calls with explicitly defined props to avoid security risks
- **Use `inertia_errors(model)`** to format validation errors (returns `{ errors: { field: "message" } }`)
- **Flash messages** (`:notice`, `:alert`) are automatically shared to frontend
- **Explicitly serialize props** using `.as_json()` to control exactly what data is sent to the client
- **Never rely on instance variables** being automatically serialized - this can accidentally leak sensitive data

## Frontend Structure

### Page Organization

```
app/frontend/pages/
└── items/
    ├── index.tsx    # List all items
    ├── show.tsx     # Show single item
    ├── new.tsx      # Create form
    └── edit.tsx     # Edit form
```

Controller renders match directory: `render inertia: "items/index"` → `app/frontend/pages/items/index.tsx`

### Example Pages

**index.tsx** - List page:

```tsx
import { Link } from "@inertiajs/react"
import { Button } from "@/components/ui/button"

type Item = {
  id: number
  name: string
  created_at: string
}

type Props = {
  items: Item[]
}

export default function Index({ items }: Props) {
  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">Items</h1>
        <Link href="/items/new">
          <Button>New Item</Button>
        </Link>
      </div>

      <div className="space-y-4">
        {items.map((item) => (
          <div key={item.id} className="rounded border p-4">
            <Link href={`/items/${item.id}`}>
              <h2 className="text-lg font-semibold">{item.name}</h2>
            </Link>
          </div>
        ))}
      </div>
    </div>
  )
}
```

**new.tsx** - Create form:

```tsx
import { Form } from "@inertiajs/react"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"

type Props = {
  item: {
    name?: string
    description?: string
  }
  errors?: {
    name?: string
    description?: string
  }
}

export default function New({ item, errors }: Props) {
  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">New Item</h1>

      <Form action="/items" method="post" resetOnSuccess>
        {({ processing }) => (
          <>
            <Field>
              <FieldLabel htmlFor="item_name">Name</FieldLabel>
              <Input
                name="item[name]"
                defaultValue={item.name}
                id="item_name"
              />
              {errors?.name && <FieldError>{errors.name}</FieldError>}
            </Field>

            <Field>
              <FieldLabel htmlFor="item_description">Description</FieldLabel>
              <Textarea
                name="item[description]"
                defaultValue={item.description}
                id="item_description"
              />
              {errors?.description && (
                <FieldError>{errors.description}</FieldError>
              )}
            </Field>

            <Button type="submit" disabled={processing}>
              Create Item
            </Button>
          </>
        )}
      </Form>
    </div>
  )
}
```

### Forms

Follow existing `<Form>` preferences from main docs:

- Uncontrolled inputs with `name` attribute
- Use `defaultValue` for initial values
- Use `resetOnSuccess` to clear form after submission
- Access reactive state via slot props: `errors`, `processing`

### Props Serialization

**Security-first approach:** Only serialize and send exactly what the page needs. Never serialize entire models.

```ruby
# ✅ CORRECT - Minimal serialization with explicit fields
items = Item.all.as_json(only: %i[id name created_at])
render inertia: "items/index", props: { items: items }

# ✅ CORRECT - With associations, explicitly specify fields
item = Item.find(params[:id]).as_json(
  only: %i[id name description],
  include: {
    author: { only: %i[id name] }
  }
)
render inertia: "items/show", props: { item: item }

# ❌ WRONG - Serializes all attributes including sensitive data
item = Item.find(params[:id]).as_json
render inertia: "items/show", props: { item: item }
```

## When to Deviate

- **Complex forms**: Use `useForm` if you need programmatic control, real-time validation, or field interdependencies
- **Non-RESTful actions**: Add custom routes/actions when CRUD doesn't fit the domain model
- **Custom layouts**: Override default `PersistentLayout` per-page if needed
- **Nested resources**: Use nested routes (`resources :projects do resources :tasks end`) when appropriate

# Testing Guide

This project uses RSpec with Inertia testing helpers. Add `:inertia` flag to request specs for Inertia matchers.

## Testing Strategy

- Prefer fixtures over factories for simple models. Use FactoryBot for complex models or associations.
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
    it { should validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
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

        expect(response).to have_http_status(:found)
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

        expect(response).to have_http_status(:found)
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

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(items_path)
    end
  end
end
```

## Inertia Matchers

Available matchers for testing Inertia responses:

| Matcher                | Usage                                                  | Description                          |
| ---------------------- | ------------------------------------------------------ | ------------------------------------ |
| `render_component`     | `expect(inertia).to render_component("items/index")`   | Asserts rendered component name      |
| `include_props`        | `expect(inertia).to include_props(items: [])`          | Asserts props include specified keys |
| `have_exact_props`     | `expect(inertia).to have_exact_props(items: [])`       | Asserts props match exactly          |
| `include_view_data`    | `expect(inertia).to include_view_data(auth: anything)` | Asserts view_data includes keys      |
| `have_exact_view_data` | `expect(inertia).to have_exact_view_data(...)`         | Asserts view_data matches exactly    |

## HTTP Status Codes

Use the correct status codes for Inertia responses:

- **Success (redirect)**: `:found` (303)
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

Use the `signed_cookies` helper to read and verify signed cookie values set by your application.

### Reading Signed Cookies

```ruby
describe "POST /session" do
  it "sets session cookie on login" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: 'secret' }

    # signed_cookies returns the decrypted value
    expect(signed_cookies[:session_id]).to eq(user.sessions.last.id)
  end
end
```

### Setting Up Authentication State in Tests

**Important:** You cannot directly set signed cookies from within tests (e.g., `cookies.signed[:user_id] = 123` in a `before` block).
**Solution:** Use your actual login endpoint to set authentication cookies:

```ruby
# spec/support/session_helper.rb
module SessionHelper
  def sign_in(user)
    post session_path, params: {
      email_address: user.email_address,
      password: user.password
    }
  end
end

# In specs
before { sign_in(user) }

it "accesses protected resource" do
  get dashboard_path
  expect(response).to have_http_status(:ok)
  expect(signed_cookies[:session_id]).to be_present
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

    expect(response).to have_http_status(:found)
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
