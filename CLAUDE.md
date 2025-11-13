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

- Prefer inertia's <Form> over `useForm`

  ```tsx
  import { Form } from '@inertiajs/react';

  export default () => (
  	<Form action="/users" method="post">
  		<input type="text" name="name" />
  		<input type="email" name="email" />
  		<button type="submit">Create User</button>
  	</Form>
  );
  ```
