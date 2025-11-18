# Builder Application

This is a Rails 8 application template using Inertia.js with React. It is a greenfield Rails app using Minitest with no existing models/controllers to reference.

## Stack Overview

### Backend

- **Rails 8.0.2** - Modern Ruby on Rails framework
- **PostgreSQL** - Primary database
- **Puma** - Web server
- **Inertia Rails** - Inertia.js adapter for Rails

### Frontend

- **Inertia.js** - Modern monolith approach that bridges Rails and React
- **React 19** - UI library for building component-based interfaces
- **TypeScript** - Type-safe JavaScript development
- **Vite** - Fast build tool and development server
- **shadcn/ui** - High-quality, accessible UI components built on Radix UI
- **Tailwind CSS v4** - Utility-first CSS framework
- **JS-Routes** - Auto-generated JavaScript routes from Rails routes `import { rootPath } from "@/routes"`

### Infrastructure

- **Solid Cache** - Database-backed cache store
- **Solid Queue** - Database-backed Active Job adapter
- **Solid Cable** - Database-backed Action Cable adapter

## Frontend Structure

### Directory Layout

- **Entry point**: `app/frontend/entrypoints/inertia.ts`
- **Styles**: `app/frontend/entrypoints/application.css`
- **Components**: `app/frontend/components/` (shadcn/ui components)
- **Utilities**: `app/frontend/lib/utils.ts`
- **Types**: `app/frontend/types/`

### Configuration Files

- **Vite**: `vite.config.ts` - Build configuration with React plugin and React Compiler
- **TypeScript**: `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`
- **shadcn/ui**: `components.json` - UI component configuration

### Development Tools

- **ESLint** - Code linting with React and TypeScript support
- **Prettier** - Code formatting with Tailwind plugin

## Styling

Tailwind CSS v4 is configured through the Vite plugin (`@tailwindcss/vite`), providing:

- Modern utility-first styling
- CSS variables for theming shadcn/ui components

The main stylesheet is located at `app/frontend/entrypoints/application.css`.

## Useful commands

- ./bin/rails generate # Lists available Rails generators
- ./bin/rails generate model # Generates a new Rails model with migrations and tests
- ./bin/rails generate migration # Generates a new Rails migration
- ./bin/rails generate authentication # Generates a full authentication system with user models and sessions
- ./bin/rails test # Runs the Rails test suite
- ./bin/rails js:routes # Generates TypeScript definitions for Rails routes
- bundle exec rubocop # Runs Ruby linter
- npm type-check # Runs TypeScript type checks
- npm lint:fix # Runs JavaScript/TypeScript linter
- npm format:fix # Prettier code formatter

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
