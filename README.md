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
