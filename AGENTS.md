# openapi_rails

## Project Overview

A Ruby gem providing an OpenAPI 3.1 toolkit for Rails. Combines test-driven spec generation, reusable schema components, and runtime request/response validation middleware.

## Development

```bash
bundle install
bundle exec rspec          # run tests
bundle exec standardrb     # lint
```

## Architecture

Single gem with modular requires:

- `lib/openapi_rails/` — core library
- `lib/openapi_rails/rspec.rb` — require this for RSpec integration
- `lib/openapi_rails/minitest.rb` — require this for Minitest integration

Key modules:

- `Core` — OpenAPI document model and builder
- `Components` — schema component system (Base, Loader, Registry, KeyTransformer)
- `DSL` — framework-agnostic test DSL (Context, OperationContext, ResponseContext, MetadataStore)
- `Adapters` — RSpec and Minitest adapters
- `Middleware` — Rack middleware for request/response validation
- `Testing` — response validator, assertions, coverage tracking
- `Generator` — OpenAPI spec file generation

## Testing

- Unit tests in `spec/openapi_rails/`
- Generator tests in `spec/generators/`
- Integration tests in `spec/integration/` — these boot the dummy Rails app
- Dummy app in `spec/dummy/` — reference implementation with Users (RSpec) and Posts (Minitest)
- Dummy app specs live in `spec/dummy/spec/` and `spec/dummy/test/` exactly as a user would write them
- RSpec pattern excludes `spec/dummy/` from autodiscovery (see `.rspec`)

## Style

- Uses [standardrb](https://github.com/standardrb/standard)
- Double-quoted strings
- No trailing commas

## Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/) — release-please generates the CHANGELOG from commit messages
- Prefix: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`

## Dependencies

- `json_schemer ~> 2.4` — sole validation engine (JSON Schema 2020-12 + OpenAPI 3.1)
- `activesupport >= 7.0`
- `railties >= 7.0`
- `rack >= 2.0`
