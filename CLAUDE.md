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

### Navigation: Link vs router.visit

- **Prefer `<Link>` for navigation** - Use the `Link` component for standard navigation (anchor tags)
- **Use `router.visit()` for programmatic navigation** - After form submissions, in callbacks, or conditional redirects

```tsx
import { Link, router } from '@inertiajs/react';

// ✅ CORRECT: Link for navigation
<Link href="/users">Users</Link>

// ✅ CORRECT: router.visit for programmatic navigation
const handleAction = () => {
  router.visit('/dashboard');
};
```

### Backend: Shared data with inertia_share

Use `inertia_share` in `InertiaController` to automatically include data in every Inertia response:

```ruby
# app/controllers/inertia_controller.rb (already configured with flash)
class InertiaController < ApplicationController
  inertia_config default_render: true
  inertia_share flash: -> { flash.to_hash }

  # Add more shared data as needed:
  inertia_share do
    {
      auth: {
        user: current_user&.as_json(only: %i[id email name])
      }
    }
  end
end
```

**CSRF tokens are handled automatically** - No configuration needed. Inertia's Rails adapter includes the proper CSRF token in all requests.

### Backend: Error handling in production

Use `rescue_from` in `ApplicationController` to return proper Inertia error pages instead of allowing modal error displays:

```ruby
class ApplicationController < ActionController::Base
  rescue_from StandardError do |exception|
    render inertia: 'Error', props: {
      status: 500,
      message: exception.message
    }, status: 500
  end
end
```

### Authorization through props

**Always pass authorization checks as props** - Don't rely on server-side helpers in React components:

```ruby
# ✅ CORRECT: Pass authorization in props
def show
  @post = Post.find(params[:id])
  render inertia: 'Posts/Show', props: {
    post: @post.as_json,
    can_edit: policy(@post).update?,
    can_delete: policy(@post).destroy?
  }
end
```

```tsx
// In React component
const PostShow = ({ post, can_edit, can_delete }) => (
  <>
    {can_edit && <Button>Edit</Button>}
    {can_delete && <Button>Delete</Button>}
  </>
);
```

### File uploads with PUT/PATCH

**Important:** When using file uploads with `PUT` or `PATCH`, use method spoofing since multipart requests don't support these methods natively:

```tsx
// ✅ CORRECT: Method spoofing for file upload with PUT
<Form action="/users/1" method="post">
  <input type="hidden" name="_method" value="put" />
  <input type="file" name="avatar" />
  <button type="submit">Upload</button>
</Form>
```

### Performance: Deferred props

Use deferred props to load non-critical data after initial page render:

```ruby
# Controller
def show
  render inertia: 'Dashboard', props: {
    user: current_user.as_json,
    stats: InertiaRails.defer { expensive_stats_calculation }
  }
end
```

Frontend receives stats after initial render. Group related deferred props with `group: 'analytics'` for parallel fetching.

### Performance: Lazy loading components

For large apps, remove `{ eager: true }` from component resolution to enable code splitting:

```ts
// app/frontend/entrypoints/inertia.ts
import.meta.glob('../pages/**/*.tsx'); // Lazy loads by default
```

Small apps benefit from single bundles (keep `eager: true`).

### Form history state preservation

If you need form state to persist across browser history navigation, provide a unique form key:

```tsx
// ✅ With form key - state persists in history
const form = useForm('CreateUser', { name: '', email: '' });

// ❌ Without key - state is lost on navigation
const form = useForm({ name: '', email: '' });
```

### Progress events (file uploads only)

Progress tracking only works during file uploads. Regular form submissions don't expose progress events.

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
