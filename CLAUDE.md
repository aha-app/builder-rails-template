# Builder Application

This is a Rails 8 application template using modern Hotwire technologies.

## Stack Overview

### Backend

- **Rails 8.0.2** - Modern Ruby on Rails framework
- **PostgreSQL** - Primary database
- **Puma** - Web server

### Frontend

- **Turbo** (via turbo-rails) - Hotwire's SPA-like page accelerator
- **Stimulus** (via stimulus-rails) - Hotwire's modest JavaScript framework
- **Importmap** - ES modules without bundling
- **Tailwind CSS 4.x** - Utility-first CSS framework
- **Propshaft** - Modern asset pipeline

### Turbo Configuration

This application is configured to use **Turbo Morph** for page refreshes:

```html
<meta name="turbo-refresh-method" content="morph" />
<meta name="turbo-refresh-scroll" content="preserve" />
```

Located in `app/views/layouts/application.html.erb:26-28`

Turbo Morph provides intelligent page updates by morphing the DOM rather than replacing it entirely, which preserves:

- Form state
- Scroll positions
- Focus states
- Third-party widget state

### Infrastructure

- **Solid Cache** - Database-backed cache store
- **Solid Queue** - Database-backed Active Job adapter
- **Solid Cable** - Database-backed Action Cable adapter

### Multi-Database Architecture

This application uses a multi-database setup:

- Primary database (application data)
- Cache database (Solid Cache)
- Queue database (Solid Queue)
- Cable database (Solid Cable)

## JavaScript Structure

- **Entry point**: `app/javascript/application.js`
- **Controllers**: `app/javascript/controllers/`
- **Import maps**: `config/importmap.rb`

The application uses Stimulus controllers for interactive behavior, with Turbo handling navigation and updates.

## Styling

Tailwind CSS is configured with the Ruby standalone build, providing modern utility-first styling without Node.js dependencies.
