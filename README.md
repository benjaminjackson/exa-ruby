# exa-ruby

Ruby client for the Exa.ai API. Search and analyze web content using neural search, question answering, code discovery, and research automation.

## Table of Contents

- [Requirements](#requirements)
  - [Installing Ruby on macOS](#installing-ruby-on-macos)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
  - [Ruby API](#ruby-api)
  - [Command Line](#command-line)
- [Features](#features)
- [Error Handling](#error-handling)
- [Documentation](#documentation)
- [Development](#development)
- [Testing](#testing)
- [Support](#support)
- [License](#license)

## Requirements

- **Ruby 3.0.0 or higher**

### Installing Ruby on macOS

If you're setting up on a fresh macOS laptop, the easiest way to get Ruby 3.x is through Homebrew:

**1. Install Homebrew** (if not already installed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Install Ruby:**

```bash
brew install ruby
```

**3. Add Homebrew's Ruby to your PATH** (follow the instructions Homebrew prints, usually adding to `~/.zshrc`):

```bash
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**4. Verify installation:**

```bash
ruby -v  # Should show Ruby 3.x
```

**Alternative: Using a version manager**

For managing multiple Ruby versions, consider [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/).

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

**Using .env file (local development)**

Create a `.env` file in your project root:

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your API key
EXA_API_KEY=your-api-key-here
```

The gem automatically loads `.env` files in development when the `dotenv` gem is installed.

**Ruby Code**

```ruby
require 'exa-ai'

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
require 'exa-ai'

Exa.configure do |config|
  config.api_key = ENV['EXA_API_KEY']
end

client = Exa::Client.new

# Search the web
results = client.search("Ruby programming language")
results.results.each { |item| puts "#{item['title']}: #{item['url']}" }

# Find similar content
similar = client.find_similar("https://arxiv.org/abs/2307.06435")
similar.results.each { |item| puts item['url'] }

# Get an answer to a question
answer = client.answer("What is machine learning?")
puts answer.answer

# Find code examples
code = client.context("React hooks")
puts code.response

# Get page contents
contents = client.get_contents(["https://ruby-lang.org"])
puts contents.results.first["text"]
```

### Command Line

```bash
# Core Search Commands
exa-ai search "Ruby programming language"
exa-ai find-similar "https://arxiv.org/abs/2307.06435"
exa-ai answer "What is machine learning?"
exa-ai context "React hooks" --tokens-num 5000
exa-ai get-contents "https://ruby-lang.org"

# Research Commands
exa-ai research-start --instructions "What species of ant are similar to honeypot ants?"
exa-ai research-get RESEARCH_ID
exa-ai research-list

# Webset Management
exa-ai webset-create --search '{"query":"technology companies","count":1}'
exa-ai webset-list --limit 5
exa-ai webset-get WEBSET_ID
exa-ai webset-update WEBSET_ID --metadata '{"updated":"true","version":"2"}'
exa-ai webset-delete WEBSET_ID --force
exa-ai webset-cancel WEBSET_ID

# Webset Searches
exa-ai webset-search-create WEBSET_ID --query "Ford Mustang" --entity custom --entity-description "vintage cars"
exa-ai webset-search-create WEBSET_ID --query "tech CEOs" --entity person --count 20
exa-ai webset-search-create WEBSET_ID --query "Y Combinator startups" --entity company
exa-ai webset-search-get WEBSET_ID SEARCH_ID
exa-ai webset-search-cancel WEBSET_ID SEARCH_ID

# Webset Items
exa-ai webset-item-list WEBSET_ID
exa-ai webset-item-get WEBSET_ID ITEM_ID
exa-ai webset-item-delete WEBSET_ID ITEM_ID --force

# Enrichments
exa-ai enrichment-create WEBSET_ID --description "Find company email" --format text
exa-ai enrichment-create WEBSET_ID --description "Company size category" --format options --options '[{"label":"Small (1-10)"},{"label":"Medium (11-50)"},{"label":"Large (51+)"}]'
exa-ai enrichment-list WEBSET_ID
exa-ai enrichment-get WEBSET_ID ENRICHMENT_ID
exa-ai enrichment-update WEBSET_ID ENRICHMENT_ID --description "Updated description"
exa-ai enrichment-delete WEBSET_ID ENRICHMENT_ID --force
exa-ai enrichment-cancel WEBSET_ID ENRICHMENT_ID

# Webset Imports
exa-ai webset-import-create companies.csv --count 100 --title "My Companies" --format csv --entity-type company
exa-ai webset-import-create data.csv --count 50 --title "Tech Startups" --format csv --entity-type company --csv-identifier 0
exa-ai webset-import-create import.csv --count 100 --title "Import" --format csv --entity-type company --metadata '{"source":"crm"}' --quiet
exa-ai webset-import-list
exa-ai webset-import-get IMPORT_ID
exa-ai webset-import-update IMPORT_ID --title "Updated Title"
exa-ai webset-import-delete IMPORT_ID
```

## Features

The gem provides complete access to Exa's API endpoints:

### Core Search
- **Search** — Neural and keyword search across billions of web pages
- **Find Similar** — Discover content similar to a given URL
- **Answer** — Generate comprehensive answers with source citations
- **Context** — Find relevant code and documentation snippets
- **Get Contents** — Extract full text content from web pages

### Research
- **Research Tasks** — Start and manage long-running research tasks with AI
- **Task Management** — Get status updates and list all research tasks

### Websets
- **Webset Management** — Create, update, delete, and list datasets of web pages
- **Webset Searches** — Run searches within websets and manage search tasks
- **Webset Items** — List, retrieve, and manage individual items in websets
- **Enrichments** — Create and manage AI-powered data enrichment tasks on websets
- **Imports** — Upload CSV files to import external data into websets

## Error Handling

```ruby
require 'exa-ai'

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

## Testing

### Running Tests

```bash
# Run unit tests (integration tests skip by default)
bundle exec rake test

# Run integration tests (VCR-based, no real API calls)
RUN_INTEGRATION_TESTS=true bundle exec rake test

# Run CLI integration tests (real API calls, requires explicit opt-in)
RUN_CLI_INTEGRATION_TESTS=true bundle exec rake test
```

### Integration Tests

**Integration tests are skipped by default** to prevent accidental API calls.

**VCR-based integration tests (`RUN_INTEGRATION_TESTS`):**
- Use recorded HTTP interactions (VCR cassettes)
- No real API calls when replaying cassettes
- Set `RUN_INTEGRATION_TESTS=true` to run them
- Safe to run during development

**CLI integration tests (`RUN_CLI_INTEGRATION_TESTS`):**
- Make real API calls through shell commands
- Consume Exa's concurrent search quota
- Set `RUN_CLI_INTEGRATION_TESTS=true` AND `EXA_API_KEY` to run them
- **Warning:** Can exhaust API quota and trigger rate limits lasting 1-2 days

**When to run integration tests:**
- VCR tests: Anytime (safe, no real API calls)
- CLI tests: Only before releases or when testing CLI-specific functionality

**Test Coverage:**
- **Unit tests** - Fast, no API calls, always run
- **VCR integration tests** - Replay cassettes, skipped by default
- **CLI integration tests** - Real API calls via shell, skipped by default

## Support

- **Documentation**: https://docs.exa.ai
- **Dashboard**: https://dashboard.exa.ai
- **Status**: https://status.exa.ai

## License

MIT License - See [LICENSE](LICENSE) file for details

---

**Built with [Exa.ai](https://exa.ai)** — The search and discovery API
