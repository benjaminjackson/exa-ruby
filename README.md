# exa-ruby

Ruby client for the Exa.ai API with comprehensive command-line interface.

**Status**: Phase 9 CLI implementation complete. All commands working with full option support.

## Installation

Add to your Gemfile:

```ruby
gem 'exa'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install exa
```

## Configuration

### Setting Your API Key

Get your API key from [dashboard.exa.ai](https://dashboard.exa.ai).

**Option 1: Environment Variable (recommended)**

```bash
export EXA_API_KEY="your-api-key-here"
```

**Option 2: Ruby Code**

```ruby
require 'exa'

Exa.configure do |config|
  config.api_key = "your-api-key-here"
end

# Or pass directly to client
client = Exa::Client.new(api_key: "your-api-key-here")
```

**Option 3: CLI Flag**

```bash
exa-api search "query" --api-key YOUR_API_KEY
```

## Ruby API Usage

### Quick Start

```ruby
require 'exa'

Exa.configure do |config|
  config.api_key = ENV['EXA_API_KEY']
end

client = Exa::Client.new

# Search the web
results = client.search("ruby programming")
puts results.results.first["title"]

# Get an answer to a question
answer = client.answer("What are the latest trends in AI?")
puts answer.answer
puts answer.citations

# Get code context
code = client.context("React hooks")
puts code.response

# Retrieve page contents
contents = client.get_contents(["https://example.com"])
puts contents.results.first["text"]
```

### Search

```ruby
client = Exa::Client.new(api_key: "your-key")

# Basic search
results = client.search("machine learning")

# With options
results = client.search("AI",
  num_results: 10,
  type: "neural",
  include_domains: ["arxiv.org", "github.com"]
)

# Access results
results.results.each do |item|
  puts item["title"]
  puts item["url"]
  puts item["score"]
end
```

### Answer

```ruby
client = Exa::Client.new(api_key: "your-key")

# Get an answer to a question
answer = client.answer("What are the best practices for API design?")

puts answer.answer        # The generated answer
puts answer.citations     # Array of source citations
puts answer.cost_dollars  # API cost

# With text content from sources
answer = client.answer("Latest AI breakthroughs", text: true)
puts answer.answer
answer.citations.each do |citation|
  puts "#{citation["title"]} (#{citation['url']})"
end
```

### Context (Code Search)

```ruby
code = client.context("authentication in Rails")

puts code.response        # The code context
puts code.results_count   # Number of results
puts code.cost_dollars    # API cost
```

### Get Contents

```ruby
contents = client.get_contents([
  "https://example.com/page1",
  "https://example.com/page2"
])

contents.results.each do |content|
  puts content["url"]
  puts content["title"]
  puts content["text"]
end
```

### Research (Async Tasks)

```ruby
# Start a research task
task = client.research_start(
  instructions: "Analyze recent AI breakthroughs",
  model: "gpt-4"
)
puts task.research_id  # Save for later polling

# Check status
status = client.research_get(task.research_id)
if status.completed?
  puts status.output
end

# List all tasks
list = client.research_list(limit: 20)
list.data.each do |task|
  puts "#{task.research_id}: #{task.status}"
end
```

## CLI Usage

### Main Commands

```bash
exa-api <command> [options]

Commands:
  search          Search the web
  answer          Generate answers to questions
  context         Get code context from repositories
  get-contents    Retrieve page contents
  research-start  Start a research task
  research-get    Get research task status
  research-list   List research tasks
```

### Search Command

Search the web using Exa's neural search:

```bash
# Basic search
exa-api search "ruby programming"

# With options
exa-api search "machine learning" --num-results 10 --type keyword

# Filter by domains
exa-api search "tutorials" \
  --include-domains "github.com,dev.to" \
  --exclude-domains "outdated-site.com"

# Pretty output
exa-api search "AI" --output-format pretty
```

**Options:**
- `QUERY` - Search query (required)
- `--num-results N` - Number of results (default: 10)
- `--type TYPE` - Search type: keyword, neural, or auto (default: auto)
- `--include-domains DOMAINS` - Comma-separated domains to include
- `--exclude-domains DOMAINS` - Comma-separated domains to exclude
- `--use-autoprompt` - Use Exa's autoprompt feature
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key (or set EXA_API_KEY env var)

### Answer Command

Generate comprehensive answers to questions using Exa's answer generation feature:

```bash
# Basic question
exa-api answer "What is the capital of France?"

# Get answer with source citations
exa-api answer "Latest developments in quantum computing"

# Include full text from sources
exa-api answer "Ruby on Rails best practices" --text

# Pretty formatted output
exa-api answer "How do I learn machine learning?" --output-format pretty
```

**Options:**
- `QUERY` - Question to answer (required)
- `--text` - Include full text content from source pages
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key (or set EXA_API_KEY env var)

**Response fields:**
- `answer` - The generated answer to your question
- `citations` - Array of source citations with URLs
- `cost_dollars` - Cost of the API request

### Context Command (Code Search)

Find code snippets and context from open-source repositories:

```bash
# Basic query
exa-api context "authentication with JWT"

# With custom token allocation
exa-api context "React hooks" --tokens-num 5000

# Text output
exa-api context "async/await patterns" --output-format text
```

**Options:**
- `QUERY` - Search query (required)
- `--tokens-num NUM` - Token allocation, integer or "dynamic" (default: dynamic)
- `--output-format FORMAT` - json or text (default: json)
- `--api-key KEY` - API key

### Get-Contents Command

Retrieve the full text content from web pages:

```bash
# Single page
exa-api get-contents "https://example.com/article"

# Multiple pages (comma-separated)
exa-api get-contents "https://site1.com,https://site2.com"

# With options
exa-api get-contents "id1,id2,id3" \
  --text \
  --highlights \
  --output-format pretty
```

**Options:**
- `IDS` - Page IDs or URLs (required, comma-separated)
- `--text` - Include full text content
- `--highlights` - Include highlighted sections
- `--summary` - Include summary
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key

### Research Commands

Start and manage long-running research tasks:

#### research-start

```bash
# Start a task
exa-api research-start --instructions "Find Ruby performance tips"

# Start and wait for completion
exa-api research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4 \
  --wait

# With output schema
exa-api research-start \
  --instructions "Extract key metrics" \
  --output-schema '{"format":"json","fields":["metric","value"]}'
```

**Options:**
- `--instructions TEXT` - Research instructions (required)
- `--model MODEL` - Model to use (e.g., gpt-4)
- `--output-schema SCHEMA` - JSON schema for structured output
- `--wait` - Wait for task to complete (with polling)
- `--events` - Show event log during polling
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key

#### research-get

```bash
# Check task status
exa-api research-get abc-123

# With events
exa-api research-get abc-123 --events

# Pretty output
exa-api research-get abc-123 --output-format pretty
```

**Options:**
- `RESEARCH_ID` - Task ID (required)
- `--events` - Include event log
- `--stream` - Stream results (premium feature)
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key

#### research-list

```bash
# List all tasks
exa-api research-list

# With pagination
exa-api research-list --limit 20

# Next page
exa-api research-list --cursor "next_page_cursor"

# Pretty table format
exa-api research-list --output-format pretty
```

**Options:**
- `--cursor CURSOR` - Pagination cursor
- `--limit N` - Results per page (default: 10)
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key

### Global Options

All commands support:
- `--api-key KEY` - Override API key
- `--output-format FORMAT` - json, pretty, or text (varies by command)
- `--help, -h` - Show command help
- `exa-api --version` - Show version
- `exa-api --help` - Show available commands

### Output Formats

**JSON (default)**
```bash
exa-api search "ruby" --output-format json
# Returns formatted JSON object
```

**Pretty**
```bash
exa-api search "ruby" --output-format pretty
# Returns human-readable format with titles, URLs, scores
```

**Text**
```bash
exa-api context "React" --output-format text
# Returns plain text output
```

## Error Handling

The CLI provides helpful error messages:

```bash
# Missing API key
$ exa search "test"
❌ Configuration Error

Missing API key. Set EXA_API_KEY or use --api-key

Solutions:
  1. Set the EXA_API_KEY environment variable:
     export EXA_API_KEY='your-api-key'
  ...

# Invalid credentials
$ exa search "test" --api-key bad-key
❌ Authentication Error

Your API key is invalid or has expired.
...

# Rate limited
$ exa search "test"  # After many requests
❌ Request Error

You've exceeded the rate limit. Please wait before trying again.
```

### Ruby API Error Handling

```ruby
client = Exa::Client.new(api_key: "test")

begin
  results = client.search("test")
rescue Exa::Unauthorized => e
  puts "Invalid API key: #{e.message}"
rescue Exa::TooManyRequests => e
  puts "Rate limited, please wait"
rescue Exa::ServerError => e
  puts "API error: #{e.message}"
end
```

## Examples

### CLI Examples

```bash
# Find Ruby tutorials
exa search "Ruby best practices" --num-results 5

# Get an answer to a question
exa answer "What is machine learning?"

# Get code examples for async/await
exa context "async/await error handling"

# Research AI trends
exa research-start --instructions "What are latest AI trends?" --wait

# Retrieve and analyze multiple pages
exa get-contents "url1,url2,url3" --text --output-format pretty
```

### Ruby API Examples

```ruby
require 'exa'

Exa.configure do |config|
  config.api_key = ENV['EXA_API_KEY']
end

client = Exa::Client.new

# Search with filtering
results = client.search("kubernetes tutorial",
  num_results: 20,
  type: "neural",
  include_domains: ["kubernetes.io", "github.com"],
  use_autoprompt: true
)

results.results.each do |item|
  puts "#{item['title']} (#{item['url']})"
end

# Get code context
code_result = client.context("Docker best practices", tokens_num: 5000)
puts code_result.response

# Start async research
task = client.research_start(
  instructions: "Summarize recent ML papers",
  model: "gpt-4"
)
puts "Task started: #{task.research_id}"

# Poll for results
loop do
  status = client.research_get(task.research_id)
  break if status.completed? || status.failed?
  sleep 5
end

if status.completed?
  puts status.output
end
```

## Development

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/cli/search_test.rb

# Run with verbose output
bundle exec rake test TESTOPTS="-v"
```

### Building the Gem

```bash
bundle exec rake build
bundle exec rake install
```

## Documentation

- [Exa API Documentation](https://docs.exa.ai)
- [API Reference](https://docs.exa.ai/reference)
- [Status Page](https://status.exa.ai)

## Support

- **Documentation**: https://docs.exa.ai
- **API Key**: https://dashboard.exa.ai
- **Status**: https://status.exa.ai

## License

MIT License - See LICENSE file for details

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Built with Exa.ai** - Search and discovery API for the web
