# Stedi

Ruby client for Stedi healthcare workflows, including:
- 270/271 eligibility checks
- Polling for processed transactions
- Retrieving 835 ERAs

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

Or pass it per client:

```ruby
client = Stedi::Client.new(
  api_key: "your_api_key",
  api_url: Stedi::Healthcare::API_URL
)
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

### Poll Processed Transactions (Core API)

Poll for newly processed transactions:

```ruby
response = Stedi.core.polling.transactions(
  start_date_time: "2026-02-11T00:00:00Z",
  page_size: 50
)
```

### Retrieve an 835 ERA Report

Fetch a specific 835 report by transaction ID:

```ruby
report = Stedi.healthcare.reports.get_835(
  transaction_id: "7647d644-9348-4596-a3b4-6830b8b48cc8"
)
```

### Poll + Fetch 835 Reports

`poll_835` polls one page from Core, filters inbound 835 transactions, fetches each report, and returns a structured response:

```ruby
result = Stedi.healthcare.reports.poll_835(
  start_date_time: "2026-02-11T00:00:00Z",
  page_size: 50
)

result.transactions    # inbound 835 transactions from the poll page
result.reports         # fetched 835 report payloads
result.next_page_token # use this on the next call to continue
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
