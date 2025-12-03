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
    @items = Item.all.as_json(only: %i[id name created_at])
    # Automatically renders "items/index" with props: { items: @items }
    # (explicit render not needed due to default_render: true)
  end

  def show
    # Automatically renders "items/show" with props: { item: @item }
  end

  def new
    @item = Item.new
    # Automatically renders "items/new" with props: { item: @item }
  end

  def edit
    # Automatically renders "items/edit" with props: { item: @item }
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to items_path, notice: "Item was successfully created."
    else
      render inertia: "items/new", props: { item: @item }.merge(inertia_errors(@item))
    end
  end

  def update
    if @item.update(item_params)
      redirect_to items_path, notice: "Item was successfully updated."
    else
      render inertia: "items/edit", props: { item: @item }.merge(inertia_errors(@item))
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

- **Use `inertia_errors(model)`** to format validation errors (returns `{ errors: { field: "message" } }`)
- **Flash messages** (`:notice`, `:alert`) are automatically shared to frontend
- **`default_render: true`** enables automatic rendering: assign instance variables (e.g., `@items`), and the matching component renders automatically
- **Use explicit `render inertia:`** only when:
  - Passing props via the `props:` hash
  - Merging errors (`inertia_errors`)
  - Rendering a different component than the default

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
import { Link } from '@inertiajs/react'
import PersistentLayout from '@/layouts/PersistentLayout'
import { Button } from '@/components/ui/button'

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
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Items</h1>
        <Link href="/items/new">
          <Button>New Item</Button>
        </Link>
      </div>

      <div className="space-y-4">
        {items.map((item) => (
          <div key={item.id} className="border p-4 rounded">
            <Link href={`/items/${item.id}`}>
              <h2 className="text-lg font-semibold">{item.name}</h2>
            </Link>
          </div>
        ))}
      </div>
    </div>
  )
}

Index.layout = (page: React.ReactNode) => (
  <PersistentLayout children={page} />
)
```

**new.tsx** - Create form:

```tsx
import { Form } from '@inertiajs/react'
import PersistentLayout from '@/layouts/PersistentLayout'
import { Field, FieldLabel, FieldError } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'

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
      <h1 className="text-2xl font-bold mb-6">New Item</h1>

      <Form action="/items" method="post" resetOnSuccess>
        {({ processing }) => (
          <>
            <Field>
              <FieldLabel>Name</FieldLabel>
              <Input name="item[name]" defaultValue={item.name} />
              {errors?.name && <FieldError>{errors.name}</FieldError>}
            </Field>

            <Field>
              <FieldLabel>Description</FieldLabel>
              <Textarea name="item[description]" defaultValue={item.description} />
              {errors?.description && <FieldError>{errors.description}</FieldError>}
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

New.layout = (page: React.ReactNode) => (
  <PersistentLayout children={page} />
)
```

### Forms

Follow existing `<Form>` preferences from main docs:
- Uncontrolled inputs with `name` attribute
- Use `defaultValue` for initial values
- Use `resetOnSuccess` to clear form after submission
- Access reactive state via slot props: `errors`, `processing`

### Props Serialization

Send only what the page needs:

```ruby
# Minimal serialization
@items = Item.all.as_json(only: %i[id name created_at])

# With associations
@item = @item.as_json(
  only: %i[id name description],
  include: {
    author: { only: %i[id name] }
  }
)
```

## When to Deviate

- **Complex forms**: Use `useForm` if you need programmatic control, real-time validation, or field interdependencies
- **Non-RESTful actions**: Add custom routes/actions when CRUD doesn't fit the domain model
- **Custom layouts**: Override default `PersistentLayout` per-page if needed
- **Nested resources**: Use nested routes (`resources :projects do resources :tasks end`) when appropriate
