# frozen_string_literal: true

source "https://rubygems.org"

# Hanami 3.0 full-stack: actions, router, views, assets and the database
# provider (hanami-db wraps rom-sql + sequel).
gem "hanami", "~> 3.0"
gem "hanami-action", "~> 3.0"
gem "hanami-assets", "~> 3.0"
gem "hanami-db", "~> 3.0"
gem "hanami-router", "~> 3.0"
gem "hanami-view", "~> 3.0"

# Boundary validation and composable operations (no strong params, no AR).
gem "dry-operation", ">= 1.0.1"
gem "dry-types", "~> 1.7"
gem "dry-validation", "~> 1.11"

gem "i18n", "~> 1.14"
gem "puma", ">= 7.1"
gem "rake"

# PostgreSQL driver, used by Sequel/rom-sql under hanami-db.
gem "pg"

# Geometry objects (SRID 4326) for mapping PostGIS geometry/geography columns.
# The Sequel PostGIS extension is enabled in the db provider configuration.
gem "rgeo"

group :development do
  gem "hanami-webconsole", "~> 3.0"
end

group :development, :test do
  gem "dotenv"
  # Syntax highlighting for SQL logs.
  gem "rouge"
  gem "rubocop", require: false
  gem "rubocop-rspec", require: false
end

group :cli, :development do
  gem "hanami-reloader", "~> 3.0"
end

group :cli, :development, :test do
  gem "hanami-rspec", "~> 3.0"
end

group :test do
  # Deterministic cleanup between examples (Sequel adapter). No factories per constitution.
  gem "database_cleaner-sequel"

  # Request and feature test support.
  gem "capybara"
  gem "rack-test"
end
