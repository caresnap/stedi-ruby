# Stedi

Ruby client for the [Stedi Healthcare API](https://www.stedi.com/docs/api-reference/healthcare), including 270/271 eligibility checks.

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

Or pass it per-client:

```ruby
client = Stedi::Client.new(api_key: "your_api_key")
```

## Usage

### Eligibility Checks (270/271)

Check patient eligibility with a payer:

```ruby
response = Stedi.healthcare.eligibility.check(
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
    service_type_codes: ["30"]  # Health benefit plan coverage
  }
)
```

### Response Handling

Responses convert camelCase keys to snake_case and support dot notation:

```ruby
response.control_number          # => "123456789"
response.subscriber.first_name   # => "Jane"
response.subscriber.member_id    # => "ABC123456"

# Access plan information
response.plan_information.plan_name    # => "Open Access Plus"
response.plan_information.group_number # => "GRP001"

# Access benefits (array)
response.benefits_information.each do |benefit|
  puts "#{benefit.name}: #{benefit.benefit_amount}"
end

# Bracket notation also works
response[:subscriber][:first_name]  # => "Jane"
response["subscriber"]["first_name"] # => "Jane"

# Convert to hash
response.to_h
```

## Error Handling

The gem raises specific errors for different failure cases:

```ruby
begin
  response = Stedi.healthcare.eligibility.check(params)
rescue Stedi::AuthenticationError => e
  # 401/403 - Invalid or missing API key
  puts "Auth failed: #{e.message}"

rescue Stedi::ValidationError => e
  # 400/422 - Invalid request parameters
  puts "Validation failed: #{e.message}"
  e.errors.each do |error|
    puts "  #{error['field']}: #{error['message']}"
  end

rescue Stedi::ApiError => e
  # 5xx - Server errors
  puts "API error (#{e.status}): #{e.message}"

rescue Stedi::Error => e
  # Base error class
  puts "Error: #{e.message}"
end
```

## Development

Run tests:

```bash
bundle install
bundle exec rake test
```
