# Builder Application

This is a Rails 8 application template using Inertia.js with React. It is a greenfield Rails app using Minitest with no existing models/controllers to reference.

## Stack

Rails 8.1 + Inertia.js + React 19 + TypeScript + Vite. Uses shadcn/ui components, Tailwind CSS v4, and JS-Routes for typed routing (`import { rootPath } from "@/routes"`). Database-backed infrastructure: Solid Cache/Queue/Cable.

### General Rules

- Early development, no users. No backwards compatibility concerns. Do things RIGHT: clean, organized, zero tech debt. Never create compatibility shims.
- WE NEVER WANT WORKAROUNDS, we always want FULL implementations that are long term sustainable for many >1000 users. so dont come up with half baked solutions
- We want thin controllers, fat models/services. All business logic in models/services with unit tests. No controller/integration tests.

## Frontend Structure

- **Entry**: `app/frontend/entrypoints/inertia.ts`
- **Styles**: `app/frontend/entrypoints/application.css`
- **Pages**: `app/frontend/pages/` (Inertia page components)
- **Components**: `app/frontend/components/` (shadcn/ui components)
- **Types**: `app/frontend/types/`

## Commands

| Command                                | Purpose                                                    |
| -------------------------------------- | ---------------------------------------------------------- |
| `./bin/ci`                             | Run all checks (Minitest, Rubocop, TS/JS lint, type check) |
| `bin/rails test`                       | Run Minitest test suite                                    |
| `./bin/rails generate model/migration` | Generate models/migrations                                 |
| `./bin/rails js:routes`                | Generate TypeScript route definitions                      |
| `npm lint:fix`                         | Fix JS/TS lint issues                                      |
| `npm format:fix`                       | Format code with Prettier                                  |
| `npm typecheck`                        | Run TypeScript type checking                               |

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
        <input name="user.name" defaultValue="John" />
        {errors.name && <div>{errors.name}</div>}

        <input name="user.skills[]" />
        <input type="file" name="user.avatar" />

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
- Automatically handles nested data (`report.description`), arrays (`report.tags[]`), file uploads

**When to use `useForm` instead:**

- Programmatic control over form state
- Real-time validation
- Complex field interdependencies

### File Uploads with PUT/PATCH

Use method spoofing (multipart doesn't support PUT/PATCH natively):

```tsx
<Form action="/users/1" method="post">
  <input type="hidden" name="_method" value="put" />
  <input type="file" name="user.avatar" />
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
  <Input name="item.name" defaultValue={item.name} id="item_name" />
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
            <Input name="item.name" defaultValue={item.name} id="item_name" />
            {errors?.name && <FieldError>{errors.name}</FieldError>}
          </Field>

          <Field>
            <FieldLabel htmlFor="item_description">Description</FieldLabel>
            <FieldDescription>
              Provide a detailed description of the item
            </FieldDescription>
            <Textarea
              name="item.description"
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
              name="item.price"
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
              <Input name="item.name" defaultValue={item.name} id="item_name" />
              {errors?.name && <FieldError>{errors.name}</FieldError>}
            </Field>

            <Field>
              <FieldLabel htmlFor="item_description">Description</FieldLabel>
              <Textarea
                name="item.description"
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

This project uses **Minitest** (not RSpec).

## Testing Strategy

- **Only write unit tests** (model tests). Do NOT write controller/integration tests for Inertia controllers.
- Delete controller or integration test files if they are generated.
- **Always use fixtures** over factories.
- Test files go in `test/models/`.

### Why No Controller/Integration Tests?

Integration tests for Inertia controllers provide minimal value:

- They test Rails + Inertia plumbing, not your business logic
- The actual rendering happens in React, which these tests don't verify
- They're slow and brittle compared to model tests
- Business logic belongs in models/services where it can be unit tested

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
