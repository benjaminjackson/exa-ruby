# exa-ruby

Ruby client for the Exa.ai API. Search and analyze web content using neural search, question answering, code discovery, and research automation.

## Installation

Add to your Gemfile:

```ruby
gem 'exa-ai'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install exa-ai
```

## Configuration

Get your API key from [dashboard.exa.ai](https://dashboard.exa.ai).

**Environment Variable (recommended)**

```bash
export EXA_API_KEY="your-api-key-here"
```

**Ruby Code**

```ruby
require 'exa'

Exa.configure do |config|
  config.api_key = "your-api-key-here"
end

# Or pass directly to client
client = Exa::Client.new(api_key: "your-api-key-here")
```

**CLI Flag**

```bash
exa-ai search "query" --api-key YOUR_API_KEY
```

## Quick Start

### Ruby API

```ruby
require 'exa'

Exa.configure do |config|
  config.api_key = ENV['EXA_API_KEY']
end

client = Exa::Client.new

# Search the web
results = client.search("ruby programming")
results.results.each { |item| puts "#{item['title']}: #{item['url']}" }

# Get an answer to a question
answer = client.answer("What are the latest trends in AI?")
puts answer.answer

# Find code examples
code = client.context("React hooks")
puts code.response

# Get page contents
contents = client.get_contents(["https://example.com"])
puts contents.results.first["text"]
```

### Command Line

```bash
# Search the web
exa-ai search "ruby programming"

# Answer a question
exa-ai answer "What is machine learning?"

# Find code examples
exa-ai context "async/await error handling"

# Get page contents
exa-ai get-contents "https://example.com"

# Start a research task
exa-ai research-start --instructions "Analyze recent ML papers" --wait
```

## Features

The gem provides complete access to Exa's API endpoints:

- **Search** — Neural and keyword search across billions of web pages
- **Answer** — Generate comprehensive answers with source citations
- **Context** — Find relevant code and documentation snippets
- **Get Contents** — Extract full text content from web pages
- **Research** — Start and manage long-running research tasks with AI

## Error Handling

```ruby
require 'exa'

client = Exa::Client.new(api_key: "your-key")

begin
  results = client.search("test")
rescue Exa::Unauthorized => e
  puts "Invalid API key: #{e.message}"
rescue Exa::TooManyRequests => e
  puts "Rate limited, please retry"
rescue Exa::ServerError => e
  puts "Server error: #{e.message}"
end
```

## Documentation

- **[Full Ruby API Documentation](./docs/API.md)** — All methods and parameters
- **[CLI Command Reference](./docs/CLI.md)** — All CLI commands and options
- **[Exa API Docs](https://docs.exa.ai)** — Exa API reference

## Development

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Running tests
- Development setup
- Code conventions
- Building and releasing

## Support

- **Documentation**: https://docs.exa.ai
- **Dashboard**: https://dashboard.exa.ai
- **Status**: https://status.exa.ai

## License

MIT License - See [LICENSE](LICENSE) file for details

---

**Built with [Exa.ai](https://exa.ai)** — The search and discovery API
