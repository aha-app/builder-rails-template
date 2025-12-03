# Builder Application

This is a Rails 8 application template using Inertia.js with React. It is a greenfield Rails app using Rspec with no existing models/controllers to reference.

**Detailed Guides:** [CRUD Pattern](docs/CRUD.md) | [Testing](docs/TESTING.md) | [Components](docs/COMPONENTS.md)

**IMPORTANT:** When implementing CRUD resources, writing tests, or working with components, you MUST read the relevant detailed guide first. These guides contain critical patterns and examples required for correct implementation.

## Stack

Rails 8.1 + Inertia.js + React 19 + TypeScript + Vite. Uses shadcn/ui components, Tailwind CSS v4, and JS-Routes for type-safe routing (`import { rootPath } from "@/routes"`). Database-backed infrastructure: Solid Cache/Queue/Cable.

## Frontend Structure

- **Entry**: `app/frontend/entrypoints/inertia.ts`
- **Styles**: `app/frontend/entrypoints/application.css`
- **Pages**: `app/frontend/pages/` (Inertia page components)
- **Components**: `app/frontend/components/` (shadcn/ui components)
- **Types**: `app/frontend/types/`

## Commands

| Command | Purpose |
|---------|---------|
| `./bin/ci` | Run all checks (RSpec, Rubocop, TS/JS lint, type check) |
| `bundle exec rspec` | Run RSpec test suite |
| `./bin/rails generate model/migration` | Generate models/migrations |
| `./bin/rails js:routes` | Generate TypeScript route definitions |
| `npm lint:fix` | Fix JS/TS lint issues |
| `npm format:fix` | Format code with Prettier |

## Inertia.js Essentials

### Navigation

- **Standard**: `<Link href="/path">`
- **Programmatic**: `router.visit('/path')` (for callbacks, conditionals)

### Rendering Behavior

`InertiaController` enables `inertia_config default_render: true` for automatic component rendering.

**Automatic rendering** (use this by default):

```ruby
class ItemsController < InertiaController
  def index
    @items = Item.all.as_json(only: %i[id name])
    # Auto-renders "items/index" with props: { items: @items }
  end
end
```

**Explicit rendering** (when needed):

```ruby
# 1. Merging additional props (e.g., validation errors)
def create
  @item = Item.new(item_params)
  unless @item.save
    render inertia: "items/new", props: { item: @item }.merge(inertia_errors(@item))
  end
end

# 2. Rendering different component
def special_view
  render inertia: "items/custom_view"
end
```

**Rule:** Use explicit `render inertia:` only when passing props via `props:` hash, merging errors, or rendering a different component. Otherwise, let automatic rendering handle it.

### Shared Data

Add global props via `inertia_share` in `InertiaController`:

```ruby
inertia_share do
  { auth: { user: current_user&.as_json(only: %i[id email name]) } }
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

See [detailed component guide](docs/COMPONENTS.md) for full reference.

**IMPORTANT:** Forms must be fully inside or fully outside Card components. Do not split Card structure across Form boundaries. See [Form and Card nesting guide](docs/COMPONENTS.md#form-and-card-component-nesting).

### Quick Reference

| Component | Import | Notes |
|-----------|--------|-------|
| Empty state | `@/components/ui/empty` | Use slot components (EmptyHeader, EmptyTitle, etc.) |
| Forms | `@/components/ui/field` | Field exports: FieldLabel, FieldError, FieldDescription |
| Inputs | `@/components/ui/input` | **No FieldInput export** - import Input separately |
| Textarea | `@/components/ui/textarea` | Import separately from field components |
| Card | `@/components/ui/card` | **Keep Form fully inside or outside Card** |

### Empty State Example

```tsx
<Empty>
  <EmptyHeader>
    <EmptyTitle>No items found</EmptyTitle>
    <EmptyDescription>Get started by creating your first item.</EmptyDescription>
  </EmptyHeader>
  <EmptyContent>{/* actions */}</EmptyContent>
</Empty>
```

## CRUD Pattern

See [full CRUD guide](docs/CRUD.md) for complete implementation pattern including:
- Model + Migration setup
- Controller implementation
- Frontend structure
- Testing patterns

Quick overview: Follow RESTful conventions, inherit from `InertiaController`, use automatic rendering where possible, test all CRUD actions with RSpec.
