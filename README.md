# Stedi

Ruby command-style client for Stedi healthcare APIs.

## Installation

Add to your Gemfile:

```ruby
gem "stedi", github: "caresnap/stedi-ruby"
```

Then run:

```bash
bundle install
```

## Configuration

Configure your API key globally:

```ruby
Stedi.configure do |config|
  config.api_key = ENV["STEDI_API_KEY"]
end
```

## Command API

All operations are exposed as behavior classes with `.build`, `.configure`, and `.call`.

### Eligibility Check (270/271)

```ruby
response = Stedi::Healthcare::Eligibility::Check.call(
  {
    trading_partner_service_id: "BCBSIL",
    provider: {
      npi: "1234567890",
      organization_name: "Example Medical Group"
    },
    subscriber: {
      member_id: "ABC123456",
      first_name: "Jane",
      last_name: "Doe",
      date_of_birth: "19800101"
    },
    encounter: {
      service_type_codes: ["30"]
    }
  }
)
```

For CMS requests that require traceability headers, pass `x_forwarded_for:` or `headers:`:

```ruby
response = Stedi::Healthcare::Eligibility::Check.call(
  params,
  x_forwarded_for: ["203.0.113.10", "198.51.100.7"]
)
```

### Batch Eligibility Checks

```ruby
batch = Stedi::Healthcare::Eligibility::Batch::Submit.call(
  [
    {
      trading_partner_service_id: "AHS",
      submitter_transaction_identifier: "ABC123456789",
      provider: {
        npi: "1234567891",
        organization_name: "ACME Health Services"
      },
      subscriber: {
        member_id: "1234567890",
        first_name: "Jane",
        last_name: "Doe",
        date_of_birth: "19000101"
      }
    }
  ],
  name: "march-2026-eligibility-batch",
  max_retry_hours: 12
)

status = Stedi::Healthcare::Eligibility::Batch::GetStatus.call(batch.batch_id)
items = Stedi::Healthcare::Eligibility::Batch::GetItemStatuses.call(batch.batch_id, page_size: 100)
results = Stedi::Healthcare::Eligibility::Batch::Poll.call(nil, batch_id: batch.batch_id, page_size: 25)
```

### Batch CLI

Use the checked-in CLI with a CSV that matches [data/batch-eligibility-template.csv](/Users/james/src/caresnap/stedi-ruby/data/batch-eligibility-template.csv):

```bash
STEDI_API_KEY=... bin/batch-eligibility data/batch-eligibility.csv
STEDI_API_KEY=... bin/batch-eligibility data/batch-eligibility.csv --status
STEDI_API_KEY=... bin/batch-eligibility data/batch-eligibility.csv --item-statuses
STEDI_API_KEY=... bin/batch-eligibility data/batch-eligibility.csv --poll
```

The submit command uses the CSV filename without its extension as the batch name and writes the returned batch ID to a sidecar file next to the CSV, such as `data/batch-eligibility.batch_id`. All request logs go to `stderr`, and the JSON payload is printed to `stdout`.

### Poll Transactions

```ruby
response = Stedi::Core::Polling::Transactions.call(
  "2026-02-11T00:00:00Z",
  page_size: 50
)
```

### Get 835 Report

```ruby
report = Stedi::Healthcare::Reports::Get835.call(
  "7647d644-9348-4596-a3b4-6830b8b48cc8"
)
```

### Poll and Fetch 835 Reports

```ruby
result = Stedi::Healthcare::Reports::Poll835.call(
  "2026-02-11T00:00:00Z",
  page_size: 50
)

result.transactions
result.reports
result.next_page_token
```

## Useful Object Interfaces

Each command/session class exposes:

- `.build(...)`
- `.configure(receiver, ...)`
- `.call(...)`
- `#call(...)`
- `Substitute.build` for inert test doubles

## Response Handling

Responses are wrapped in `Stedi::Response`, which supports snake_case dot access:

```ruby
response.control_number
response.subscriber.first_name
response.to_h
```

## Error Handling

```ruby
begin
  Stedi::Healthcare::Eligibility::Check.call(params)
rescue Stedi::AuthenticationError => e
  puts e.message
rescue Stedi::ValidationError => e
  puts e.errors.inspect
rescue Stedi::ApiError => e
  puts e.status
end
```

## Development

Run tests:

```bash
bundle install
bundle exec rake test
```
