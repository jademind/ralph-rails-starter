# Rails Project Template - Agent Guide

This document provides a comprehensive overview of the Rails project structure and essential commands for developers and AI agents working with this Ruby on Rails 8.1 project template.

## Project Overview

This is a Ruby on Rails 8.1 application template following the **Model-View-Controller (MVC)** architecture pattern. Rails emphasizes two core principles:

- **Don't Repeat Yourself (DRY)**: Write code once and reuse it throughout the application
- **Convention Over Configuration**: Sensible defaults reduce the need for configuration files

## Prerequisites / Core technologies

- **Ruby**: Version 3.4 or newer (specified in `.ruby-version`)
- **Rails**: Version 8.1
- **Bundler**: For dependency management
- **Database**: SQLite per default
- **CSS Framework**: Tailwindcss v4.1.18

## Project Structure

```
.
├── app/                    # Core application code (focus here for most work)
│   ├── controllers/       # Handle HTTP requests and business logic
│   ├── models/            # Database models and business logic
│   ├── views/             # HTML templates and view logic
│   ├── helpers/           # View helper methods
│   ├── mailers/           # Email handling
│   ├── jobs/              # Background job processing
│   └── assets/            # CSS, JavaScript, images
├── bin/                    # Executable scripts (rails, setup, etc.)
├── config/                 # Application configuration
│   ├── routes.rb          # URL routing definitions
│   ├── database.yml       # Database configuration
│   ├── environments/      # Environment-specific settings
│   ├── credentials.yml.enc # Encrypted credentials
│   └── master.key         # Encryption key (keep secure!)
├── db/                     # Database files
│   ├── migrate/           # Database migration files
│   ├── schema.rb          # Current database schema
│   └── seeds.rb           # Sample data for development
├── test/                   # Test files (unit, integration, system)
├── public/                 # Static files served directly
├── storage/                # Uploaded files and Active Storage data
├── vendor/                 # Third-party code
│   └── bundle/            # Bundled gems (via bundle install --path)
├── Gemfile                 # Ruby gem dependencies
├── Gemfile.lock           # Locked gem versions
└── README.md              # Project documentation
```

### Key Directories Explained

- **app/**: Contains 90% of your application code. Rails auto-loads files from here.
- **config/routes.rb**: Maps URLs to controller actions (e.g., `GET /posts` → `PostsController#index`)
- **db/migrate/**: Version-controlled database changes (never edit old migrations)
- **config/credentials.yml.enc**: Encrypted storage for API keys, secrets (edit with `rails credentials:edit`)

## Essential Rails Commands

All commands should be prefixed with `bin/rails` or `bundle exec rails` to use the project's Rails version.

### Server Management

```bash
# Start the development server (http://localhost:3000)
bin/rails server
bin/rails s                 # Short alias

# Start on different port
bin/rails s -p 3001

# Start in production mode
bin/rails s -e production
```

### Code Generation

```bash
# Generate a new model with attributes
bin/rails generate model Post title:string body:text
bin/rails g model Post title:string body:text  # Short alias

# Generate a controller with actions
bin/rails generate controller Posts index show new create

# Generate a complete CRUD resource (model, views, controller, routes)
bin/rails generate scaffold Post title:string body:text published:boolean

# Generate a resource (model, controller, routes - no views)
bin/rails generate resource Post title:string body:text

# Destroy/undo generated files
bin/rails destroy model Post
bin/rails d model Post      # Short alias
```

### Database Commands

```bash
# Create the database
bin/rails db:create

# Run pending migrations
bin/rails db:migrate

# Rollback the last migration
bin/rails db:rollback

# Rollback multiple migrations
bin/rails db:rollback STEP=3

# Reset database (drop, create, migrate)
bin/rails db:reset

# Drop and recreate from schema
bin/rails db:schema:load

# Load seed data from db/seeds.rb
bin/rails db:seed

# Full setup (create, migrate, seed)
bin/rails db:setup

# Check migration status
bin/rails db:migrate:status
```

### Interactive Console

```bash
# Open Rails console (interactive Ruby shell with full app context)
bin/rails console
bin/rails c                 # Short alias

# Open in sandbox mode (changes are rolled back on exit)
bin/rails c --sandbox

# Access database console directly
bin/rails dbconsole
bin/rails db                # Short alias
```

### Routing & Debugging

```bash
# List all application routes
bin/rails routes

# Search for specific routes
bin/rails routes | grep posts
bin/rails routes -g posts   # Using grep flag

# Show routes for specific controller
bin/rails routes -c posts

# Display application information
bin/rails about

# Show middleware stack
bin/rails middleware
```

### Testing

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/post_test.rb

# Run specific test by line number
bin/rails test test/models/post_test.rb:12

# Run tests matching pattern
bin/rails test test/models/post_test.rb -n test_should_validate
```

### Credentials Management

```bash
# Edit encrypted credentials (creates if not exists)
bin/rails credentials:edit

# Edit credentials for specific environment
bin/rails credentials:edit --environment production

# Show credentials (development only)
bin/rails credentials:show
```

### Code Maintenance

```bash
# Execute Ruby code in Rails context
bin/rails runner "puts User.count"
bin/rails runner script/batch_process.rb

# Find code annotations (TODO, FIXME, OPTIMIZE)
bin/rails notes

# Find specific annotation type
bin/rails notes -a TODO

# Generate cryptographic secret
bin/rails secret
```

### Asset Management

```bash
# Precompile assets for production
bin/rails assets:precompile

# Clean compiled assets
bin/rails assets:clean

# Remove all compiled assets
bin/rails assets:clobber
```

### Code Formatting

```bash
# Run rubcop to find code formatting issues
bin/rubocop

# Remove autocorrecting code formatting issues
bin/rubocop --fix
```


## Common Workflows

### Creating a New Feature

1. Generate model with migration:
   ```bash
   bin/rails g model Article title:string content:text published_at:datetime
   ```

2. Review and run migration:
   ```bash
   bin/rails db:migrate
   ```

3. Generate controller:
   ```bash
   bin/rails g controller Articles index show new create edit update destroy
   ```

4. Add routes in `config/routes.rb`:
   ```ruby
   resources :articles
   ```

5. Implement controller actions and views

6. Add tests and run:
   ```bash
   bin/rails test
   ```

### Making Database Changes

1. Generate migration:
   ```bash
   bin/rails g migration AddStatusToArticles status:string
   ```

2. Edit migration file in `db/migrate/`

3. Run migration:
   ```bash
   bin/rails db:migrate
   ```

4. Update model validations and tests


## Rails 8.1 Features

- **Propshaft**: Modern asset pipeline (replaces Sprockets)
- **Kamal**: Built-in deployment to containers
- **Authentication Generator**: Quick auth scaffolding
- **Action Mailer**: Enhanced email delivery
- **Active Storage**: Direct file uploads to cloud storage
- **Hotwire**: Modern JavaScript framework (Turbo + Stimulus)

## Environment Configuration

Rails supports three default environments:

- **development**: Local development with code reloading
- **test**: Automated testing with isolated database
- **production**: Optimized for performance and security

Switch environments with the `-e` flag or `RAILS_ENV` variable:

```bash
bin/rails s -e production
RAILS_ENV=test bin/rails db:migrate
```

## Core Patterns

- MVC (Model-View-Controller) - Rails' fundamental architectural pattern separating data (models), presentation (views), and business logic (controllers)
- Fat Models, Skinny Controllers - Keep business logic in models while controllers only handle HTTP request/response coordination
- Service Objects - Extract complex business logic into dedicated Plain Old Ruby Objects (POROs) with a single public method (usually call or execute)
- Form Objects - Encapsulate form handling and validation logic separate from models, especially useful for multi-model forms
- Query Objects - Isolate complex ActiveRecord queries into reusable classes to keep models and controllers clean
- Concerns - Use Rails modules to share functionality across models or controllers (e.g., Authenticatable, Searchable)
- Decorators/Presenters - Wrap models to add view-specific logic and formatting without polluting model classes
- Policy Objects - Define authorization rules in dedicated Pundit policies separate from models and controllers
- Serializers - Transform model data into JSON or other formats for API responses using dedicated serializer classes
- Value Objects - Represent immutable domain concepts (like Money, Address) as simple objects with equality based on values
- Interactors - Coordinate multiple service objects and handle transaction management for complex business operations
- Callbacks - Use ActiveRecord lifecycle hooks (before_save, after_create, etc.) for automatic model behavior
- Scopes - Define reusable query fragments as named methods on models for cleaner and chainable queries
- STI (Single Table Inheritance) - Store related models with shared attributes in one table using a type column
- Polymorphic Associations - Allow a model to belong to multiple other model types using *_type and *_id columns
- Active Job - Extract long-running tasks into background jobs for asynchronous processing
- Repository Pattern - Abstract data access logic behind repository classes to decouple persistence from business logic
- Builder Pattern - Construct complex objects step-by-step using dedicated builder classes
- Internationalization - Use i18n keys in all views, tests and controllers. Use relative translation keys in views (e.g., t('.title')) that automatically resolve based on the view path (views.controller_name.action_name.title) for DRY, maintainable internationalization.


## Tips for AI Agents

1. **Always run migrations**: After generating models, run `bin/rails db:migrate`
2. **Check routes**: Use `bin/rails routes` to verify URL mappings
3. **Use console for testing**: Test queries and methods in `bin/rails c` before implementing
4. **Follow RESTful conventions**: Use standard actions (index, show, new, create, edit, update, destroy)
5. **Bundle exec**: If you see gem-related errors, prefix commands with `bundle exec`
6. **Read logs**: Check `log/development.log` for detailed request information
7. **Test-driven development**: Write tests before implementing features when possible

## Additional Resources

- **Official Rails Guides**: https://guides.rubyonrails.org/
- **Rails API Documentation**: https://api.rubyonrails.org/
- **Rails Command Line**: https://guides.rubyonrails.org/command_line.html
- **Active Record Basics**: https://guides.rubyonrails.org/active_record_basics.html
- **Routing Guide**: https://guides.rubyonrails.org/routing.html

