# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Concerto (Fresh) is a digital signage management system built with Ruby on Rails 8. It allows users to manage content that is displayed on screens throughout a network. This is a radical simplification of Concerto 2, designed for long-term support and easy maintenance.

The application consists of:
- **Backend**: Rails 8 API and admin interface
- **Frontend Player**: Vue 3 components powered by Vite for the screen player interface
- **Authentication**: Devise with OpenID Connect SSO support
- **Authorization**: Pundit for role-based access control via group memberships

## Core Architecture

### Data Model

The system is built around these key relationships:

1. **Content Flow**: `Content` → `Submission` → `Feed` → `Subscription` → `Screen`
   - Content (RichText, Graphic, Video) is submitted to Feeds
   - Feeds are subscribed to specific Fields on Screens via Subscriptions
   - Content has start_time/end_time for scheduling (see `active`, `expired`, `upcoming` scopes)

2. **Screen Configuration**: `Screen` → `Template` → `Position` → `Field`
   - Each Screen uses a Template that defines layout Positions
   - Positions reference Fields (content areas like "main", "ticker", etc.)
   - Templates can have attached images for preview

3. **Authorization**: `User` ↔ `Membership` ↔ `Group` ← `Screen`
   - Users belong to Groups via Memberships (role: member or admin)
   - Screens belong to a Group
   - Authorization checks user's role in the screen's group
   - Special system admin users (is_system_user: true) have elevated privileges

### Content Types

Content uses Single Table Inheritance (STI):
- `RichText`: Text-based content stored in `text` field
- `Graphic`: Image-based content via ActiveStorage
- `Video`: Video content via ActiveStorage
- Base class: `Content` with common fields (duration, start_time, end_time, user_id)

### Feed Types

Feeds also use STI:
- `RssFeed`: Automatically pulls content from RSS feeds (has refresh/cleanup actions)
- Base class: `Feed` with config JSON field for type-specific settings

## Development Commands

### Running the Application

```shell
bin/dev
```

Starts the Rails server and Vite dev server via Foreman (see Procfile.dev).

### Testing

```shell
# Ruby unit tests
bin/rails test

# Ruby system tests (browser-based)
bin/rails test:system

# Frontend tests (Vue components)
yarn run vitest

# Run a single test file
bin/rails test test/models/content_test.rb

# Run a single test by line number
bin/rails test test/models/content_test.rb:42
```

### Database

```shell
# Create and migrate database
bin/rails db:create db:migrate

# Seed sample data
bin/rails db:seed

# Reset database (drop, create, migrate, seed)
bin/rails db:reset
```

### Code Quality

```shell
# Run RuboCop (uses rubocop-rails-omakase)
bin/rails rubocop

# Auto-fix RuboCop issues
bin/rails rubocop -A

# Security audit
bundle exec bundler-audit check --update

# Security vulnerability scan
bundle exec brakeman
```

### Frontend Development

```shell
# Install JavaScript dependencies
yarn install

# Add a new importmap package
bin/importmap pin package-name

# Run ESLint
yarn run eslint "{app,test}/frontend/**/*.{js,vue}"

# Auto-fix ESLint issues
yarn run eslint --fix "{app,test}/frontend/**/*.{js,vue}"
```

### Pre-Commit Checklist

**IMPORTANT**: Before committing code or creating a pull request, always run:

```shell
# 1. Run all tests
bin/rails test
yarn run vitest

# 2. Run linters
bin/rails rubocop -A  # Ruby code (auto-fix)
yarn run eslint --fix "{app,test}/frontend/**/*.{js,vue}"  # Frontend code (auto-fix)

# 3. Verify everything passes
bin/rails rubocop
yarn run eslint "{app,test}/frontend/**/*.{js,vue}"
```

If any linter or test fails, fix the issues before committing.

### Deployment

Uses Kamal for Docker-based deployment (see config/deploy.yml and Dockerfile).

## Authorization System

This project uses Pundit for authorization. See `docs/authorization_guidelines.md` for complete details.

### Key Points

- Every controller action must call `authorize @record` or `policy_scope(Model)`
- Policies are in `app/policies/` and follow naming: `ModelPolicy`
- Use `after_action :verify_authorized` and `after_action :verify_policy_scoped` in controllers
- Authorization is based on group membership roles (member vs admin)
- The `ScreenPolicy` is the reference implementation

### Common Patterns

```ruby
# In controllers
authorize @screen  # Calls ScreenPolicy#action?
policy_scope(Screen)  # Calls ScreenPolicy::Scope#resolve

# In views
<% if policy(@screen).edit? %>
  <%= link_to "Edit", edit_screen_path(@screen) %>
<% end %>

# Strong parameters with policy
def screen_params
  params.require(:screen).permit(policy(@screen).permitted_attributes)
end
```

## Frontend Architecture

The frontend uses a hybrid approach:

### Admin Interface
- Rails views with Turbo/Stimulus for the admin panel
- Tailwind CSS for styling (see `docs/concerto-style-guide.md` for design system)
- Hotwire for SPA-like interactions without complex JavaScript

### Player Interface
- Vue 3 components for the screen player (`app/frontend/`)
- Vite for bundling (config in `config/vite.json` and `vite.config.ts`)
- Entry point: `app/frontend/entrypoints/player.js`
- Components in `app/frontend/components/`
- Frontend route: `/frontend/:id` renders the player

### Adding JavaScript Dependencies

Use ImportMaps for admin interface dependencies:
```shell
bin/importmap pin @stimulus-components/dropdown
```

Use yarn/npm for frontend player dependencies (managed via Vite).

## Important Conventions

### Icons
Copy SVG icons from https://heroicons.com/ (per design spec, uses line icons with 1.5px stroke width).

### Styling
Follow the design system in `docs/concerto-style-guide.md`:
- Color palette based on Brand Blue (#007BFF)
- Typography uses 'Inter' font family
- Spacing uses 4px-based scale matching Tailwind
- Components should match the specified UI library patterns

### Testing
- Write policy tests in `test/policies/` for authorization logic
- Write controller tests in `test/controllers/` to verify authorization integration
- Frontend component tests go in `test/frontend/`

### Code Style
- Follow rubocop-rails-omakase for Ruby (see `.rubocop.yml`)
- ESLint config in `eslint.config.js` for JavaScript

## File Organization

```
app/
├── controllers/        # Rails controllers
│   └── frontend/      # Frontend player controllers
├── models/            # ActiveRecord models (STI for Content, Feed)
├── policies/          # Pundit authorization policies
├── views/             # ERB templates
├── frontend/          # Vue 3 application
│   ├── components/    # Vue components
│   └── entrypoints/   # Vite entry points
└── javascript/        # Stimulus controllers and importmap JS

config/
├── routes.rb          # Application routes
├── vite.json          # Vite Rails configuration
└── deploy.yml         # Kamal deployment config

db/
├── schema.rb          # Database schema (source of truth)
└── migrate/           # Database migrations

test/
├── controllers/       # Controller tests
├── models/           # Model tests
├── policies/         # Policy tests
├── system/           # System/browser tests
└── frontend/         # Frontend component tests

docs/
├── authorization_guidelines.md  # Detailed Pundit usage guide
└── concerto-style-guide.md     # UI/UX design specification
```

## Key Relationships to Remember

When working with subscriptions and content rendering:

1. A Screen subscribes to Feeds through Subscriptions (which reference a specific Field)
2. Content flows to a Screen when it's submitted to a Feed that the Screen subscribes to
3. The `should_render_in?(position)` method on Content determines render eligibility
4. Content has active/expired/upcoming scopes based on start_time/end_time
5. RSS feeds can have unused content (expired with no text, marked with "(unused)" in name)

## Authentication & SSO

- Primary authentication via Devise
- SSO support via OmniAuth OpenID Connect (config in local files: `sso_config.md.local`)
- Users can be created via SSO (`provider` and `uid` fields) or standard Devise registration

## Settings System

Application settings use a key-value store via the `Setting` model:
- Accessed via admin interface at `/admin/settings`
- Supports different value types (stored in `value_type` field)
- Examples: site name, default durations, RSS feed configuration

## Notes

- Rails 8 uses solid_queue, solid_cache, and solid_cable for background jobs, caching, and ActionCable
- The application uses SQLite in development (see `config/database.yml`)
- Deployment is via Kamal to any Docker-compatible host
- Vite dev server runs on port 3036 (development) or 3037 (test)
