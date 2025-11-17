# Builder Rails Template

A Rails 8 application template with Inertia.js, React, and custom ActiveStorage with efficient nginx-based file streaming.

## Quick Start

```bash
bin/setup
bin/dev
```

## Running Tests

```bash
# All tests
bin/rails test

# File storage tests
bin/rails test test/services/blob_service_storage_test.rb
```

## File Storage

This application includes a production-ready ActiveStorage implementation using nginx's x-accel-redirect pattern for efficient file uploads and downloads.

### Key Features

- **Memory efficient** - Files stream through nginx, not Rails
- **Scalable** - No blocking on file operations
- **Secure** - JWT-based authentication with signed blob IDs
- **ActiveStorage compatible** - Works with all standard features

### Configuration

Set the following environment variables:

```bash
BLOB_UPLOADS_RW=your-jwt-token
BLOB_SERVICE_URL=http://blob-service.example.com:9003  # Optional
```

### Usage

```ruby
class Document < ApplicationRecord
  has_one_attached :file
  has_many_attached :attachments
end

# Server-side attachment
document.file.attach(io: File.open("file.pdf"), filename: "file.pdf")
document.file.url  # Get download URL

# Client-side direct upload (HTML form)
<%= form.file_field :file, direct_upload: true %>
```

Direct uploads are enabled by default via Active Storage JavaScript. See [CLAUDE.md](CLAUDE.md) for detailed implementation.

## Documentation

See [CLAUDE.md](CLAUDE.md) for complete documentation on:
- Stack architecture and infrastructure
- File storage implementation details
- Development patterns and conventions
- nginx configuration requirements

## Fred codes

The application is auto booted with the app.sh script and kept running in the background.
