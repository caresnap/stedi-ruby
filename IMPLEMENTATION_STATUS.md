# Stedi Ruby Gem - Implementation Status

## Current Version

- Gem version: `0.3.0`
- Architecture: command-style useful objects
- Test framework: `minitest`

## Public API (Command-Style)

Primary operations:

- `Stedi::Healthcare::Eligibility::Check.call(params)`
- `Stedi::Healthcare::Eligibility::Batch::Submit.call(items, name: nil, max_retry_hours: nil)`
- `Stedi::Healthcare::Eligibility::Batch::GetStatus.call(batch_id)`
- `Stedi::Healthcare::Eligibility::Batch::GetItems.call(batch_id, page_token: nil, page_size: nil, state: nil)`
- `Stedi::Healthcare::Eligibility::Batch::Poll.call(start_date_time = nil, batch_id: nil, page_token: nil, page_size: nil)`
- `Stedi::Core::Polling::Transactions.call(start_date_time = nil, page_token: nil, page_size: nil)`
- `Stedi::Healthcare::Reports::Get835.call(transaction_id)`
- `Stedi::Healthcare::Reports::Poll835.call(start_date_time = nil, page_token: nil, page_size: nil)`

## Core Design

- One behavior class per endpoint/workflow.
- Session-style transport via `Stedi::HTTP::Session#call(method, path, params:, body:)`.
- Domain sessions:
  - `Stedi::Core::Session`
  - `Stedi::Healthcare::Session`
  - `Stedi::Manager::Session`
- Dependency wiring via `evt-dependency` (`Dependency`).
- Logging via `evt-log` (`Log::Dependency`) with per-class tags.
- Every behavior class exposes `.build`, `.configure`, `.call`, instance `#call`.
- Every behavior/session class includes a `Substitute` module for inert DI tests.

## Response and Errors

- API payloads return `Stedi::Response`.
- Error semantics preserved:
  - `Stedi::AuthenticationError`
  - `Stedi::ValidationError`
  - `Stedi::ApiError`

## Notes

- This is a breaking redesign.
- Facade APIs (`Stedi.healthcare`, `Stedi.core`, aggregate endpoint classes) are removed.
- Preferred usage is direct command invocation.
