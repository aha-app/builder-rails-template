# Builder Application

This is a Rails 8 application template using Inertia.js with React. It is a greenfield Rails app using Minitest with no existing models/controllers to reference.

## Stack

Rails 8.1 + Inertia.js + React 19 + TypeScript + Vite. Uses shadcn/ui components, Tailwind CSS v4, and JS-Routes for type-safe routing (`import { rootPath } from "@/routes"`). Database-backed infrastructure: Solid Cache/Queue/Cable.

## Frontend Structure

- **Entry**: `app/frontend/entrypoints/inertia.ts`
- **Styles**: `app/frontend/entrypoints/application.css`
- **Pages**: `app/frontend/pages/` (Inertia page components)
- **Components**: `app/frontend/components/` (shadcn/ui components)
- **Utils**: `app/frontend/lib/utils.ts`
- **Types**: `app/frontend/types/`

## Styling

Tailwind CSS v4 via Vite plugin. Stylesheet: `app/frontend/entrypoints/application.css`

## Useful commands

- ./bin/rails generate # Lists available Rails generators
- ./bin/rails generate model # Generates a new Rails model with migrations and tests
- ./bin/rails generate migration # Generates a new Rails migration
- ./bin/rails generate authentication # Generates a full authentication system with user models and sessions
- ./bin/rails test # Runs the Rails test suite
- ./bin/ci # Runs Rails tests, Rubocop, JS/TS lint, and TypeScript type checks. All in one command.
- ./bin/rails js:routes # Generates TypeScript definitions for Rails routes
- bundle exec rubocop # Runs Ruby linter
- npm type-check # Runs TypeScript type checks
- npm lint:fix # Runs JavaScript/TypeScript linter
- npm format:fix # Prettier code formatter

## Inertia.js Patterns & Gotchas

### Navigation

- Prefer `<Link href="/path">` for standard navigation
- Use `router.visit('/path')` for programmatic navigation (callbacks, conditionals)

### Shared data

Add global props via `inertia_share` in `InertiaController`:

```ruby
inertia_share do
  { auth: { user: current_user&.as_json(only: %i[id email name]) } }
end
```

CSRF tokens are handled automatically.

### Authorization

Pass authorization checks as props (don't rely on server helpers in React):

```ruby
render inertia: 'Posts/Show', props: {
  post: @post.as_json,
  can_edit: policy(@post).update?
}
```

### File uploads with PUT/PATCH

Use method spoofing for file uploads with PUT/PATCH (multipart doesn't support these natively):

```tsx
<Form action="/users/1" method="post">
  <input type="hidden" name="_method" value="put" />
  <input type="file" name="avatar" />
</Form>
```

### Performance

**Deferred props:** `stats: InertiaRails.defer { expensive_calculation }` loads after initial render. Group with `group: 'name'` for parallel fetching.

**Lazy loading:** Remove `{ eager: true }` from `import.meta.glob('../pages/**/*.tsx')` to enable code splitting (large apps only).

### Misc

- **Form history:** Use `useForm('UniqueKey', {...})` to persist form state across browser navigation
- **Progress events:** Only work during file uploads, not regular form submissions

## Preferences

- **Prefer `<Form>` over `useForm`** - The `<Form>` component handles 90% of cases and should be your default choice.

**Use uncontrolled inputs:**

- Use `name` attribute (not `value` + `onChange`)
- Use `defaultValue` for initial values (not `value`)
- Let the browser handle form state naturally
- Automatically handles nested data (`report[description]`), arrays (`tags[]`), and dotted notation (`user.name`)
- Supports file uploads out of the box

**Reset forms after submission:**

- Use `resetOnSuccess` prop to clear form after successful submission
- Use `resetOnError` if you need to reset after validation errors
- Don't use React `key` prop or other workarounds to force remounts

**Access reactive state via slot props:**

- `errors`, `processing`, `isDirty`, `wasSuccessful`, etc.

```tsx
import { Form } from '@inertiajs/react';

// ✅ CORRECT: Uncontrolled form with resetOnSuccess
export default () => (
  <Form action="/users" method="post" resetOnSuccess>
    {({ errors, processing }) => (
      <>
        <input type="text" name="name" defaultValue="John" />
        {errors.name && <div>{errors.name}</div>}

        <input type="text" name="user.skills[]" />
        <input type="file" name="avatar" />

        <button type="submit" disabled={processing}>
          {processing ? 'Submitting...' : 'Submit'}
        </button>
      </>
    )}
  </Form>
);

// ❌ WRONG: Controlled inputs with useState
const [name, setName] = useState('');
<Form action="/users" method="post">
  <input value={name} onChange={(e) => setName(e.target.value)} />
</Form>;
```

**When to use `useForm` instead:**

- You need programmatic control over form state
- Implementing real-time validation
- Fields have complex interdependencies
- You need to track `isDirty`, `processing`, etc. in your component logic

- New Rails controllers should inherit from `InertiaController`

  ```ruby
  class UsersController < InertiaController
  end
  ```

### Component patterns: Empty state

Use `Empty` component slots (no direct `title`/`description` props):

```tsx
<Empty>
  <EmptyHeader>
    <EmptyTitle>Title</EmptyTitle>
    <EmptyDescription>Description</EmptyDescription>
  </EmptyHeader>
  <EmptyContent>{/* actions */}</EmptyContent>
</Empty>
```

Import from `@/components/ui/empty`

## Standard CRUD Pattern

Follow this pattern when implementing CRUD resources (boards, projects, tasks, etc.) unless explicitly requested otherwise.

### Backend structure

1. **Model + Migration**: Add model with validations, enforce constraints in DB where practical (`null: false`, etc.)
2. **Routes**: Use `resources :items` (or set `root "items#index"` if applicable)
3. **Controller**: Inherit from `InertiaController`, implement standard actions:

```ruby
class ItemsController < InertiaController
  before_action :set_item, only: %i[show edit update destroy]

  def index
    # render inertia: "Items/Index" (automatic via default_render: true)
    # props via @items or local variable passed to render
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to items_path, notice: "Created successfully."
    else
      # Use inertia_errors() helper from InertiaController
      render inertia: "Items/New", props: { item: @item }.merge(inertia_errors(@item))
    end
  end

  # Similar pattern for update/destroy
end
```

**Key points:**

- Use `inertia_errors(model)` to format validation errors (returns `{ errors: { field: "message" } }`)
- Flash messages (`:notice`, `:alert`) are automatically shared to frontend
- `default_render: true` means explicit `render inertia:` is optional for simple cases

### Frontend structure

**Page organization:**

- Pages under `app/frontend/pages/ResourceName/` (PascalCase directory)
- Standard pages: `Index.tsx`, `Show.tsx`, `New.tsx`, `Edit.tsx`
- Controller renders match directory: `render inertia: "Items/Index"`

**Forms:** Follow existing `<Form>` preferences (uncontrolled inputs, `resetOnSuccess`, etc.)

**Props serialization:**

```ruby
# Minimal - only send what the page needs
items.as_json(only: %i[id name created_at])
```

### Testing

- **Models**: `test/models/item_test.rb` - validate presence, length, associations
- **Controllers**: `test/controllers/items_controller_test.rb` - test all CRUD actions (happy path + validation failures)

### When to deviate

- **Complex forms**: Use `useForm` if you need programmatic control, real-time validation, or field interdependencies
- **Non-RESTful actions**: Add custom routes/actions when CRUD doesn't fit the domain model
- **Custom layouts**: Override default `PersistentLayout` per-page if needed
