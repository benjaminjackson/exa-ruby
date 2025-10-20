# exa-ruby

Ruby client for the Exa.ai API with comprehensive command-line interface.

**Status**: Phase 9 CLI implementation complete. All commands working with full option support.

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
exa-ai search "query" --api-key YOUR_API_KEY
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
exa-ai <command> [options]

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
exa-ai search "ruby programming"

# With options
exa-ai search "machine learning" --num-results 10 --type keyword

# Filter by domains
exa-ai search "tutorials" \
  --include-domains "github.com,dev.to" \
  --exclude-domains "outdated-site.com"

# Pretty output
exa-ai search "AI" --output-format pretty
```

**Basic Options:**
- `QUERY` - Search query (required)
- `--num-results N` - Number of results (default: 10)
- `--type TYPE` - Search type: keyword, neural, or auto (default: auto)
- `--include-domains DOMAINS` - Comma-separated domains to include
- `--exclude-domains DOMAINS` - Comma-separated domains to exclude
- `--use-autoprompt` - Use Exa's autoprompt feature
- `--output-format FORMAT` - json or pretty (default: json)
- `--api-key KEY` - API key (or set EXA_API_KEY env var)

#### Advanced Search Options

**Date Filtering:**
```bash
# Filter by published date
exa-ai search "AI research" \
  --start-published-date "2025-01-01T00:00:00.000Z" \
  --end-published-date "2025-12-31T23:59:59.999Z"

# Filter by crawl date
exa-ai search "news" \
  --start-crawl-date "2025-10-01T00:00:00.000Z" \
  --end-crawl-date "2025-10-31T23:59:59.999Z"
```

**Text Filtering:**
```bash
# Results must include specific phrase
exa-ai search "machine learning" --include-text "neural networks"

# Results must exclude specific phrase
exa-ai search "programming" --exclude-text "paid-partnership"

# Combine inclusion and exclusion
exa-ai search "Python" \
  --include-text "open source" \
  --exclude-text "deprecated"
```

**Content Extraction:**
```bash
# Extract full webpage text
exa-ai search "Ruby" --text

# Extract text with options
exa-ai search "AI" \
  --text \
  --text-max-characters 3000 \
  --include-html-tags

# Generate AI summaries
exa-ai search "climate change" \
  --summary \
  --summary-query "What are the main points?"

# Format results as context for LLM RAG
exa-ai search "kubernetes" \
  --context \
  --context-max-characters 5000

# Crawl subpages
exa-ai search "documentation" \
  --subpages 1 \
  --subpage-target about \
  --subpage-target docs

# Extract links from results
exa-ai search "web development" \
  --links 3 \
  --image-links 2
```

**Advanced Ruby API:**
```ruby
client = Exa::Client.new(api_key: "your-key")

# Date range filtering
results = client.search("AI research",
  start_published_date: "2025-01-01T00:00:00.000Z",
  end_published_date: "2025-12-31T23:59:59.999Z"
)

# Text filtering
results = client.search("machine learning",
  include_text: ["neural networks"],
  exclude_text: ["cryptocurrency"]
)

# Full webpage text extraction
results = client.search("Ruby",
  text: {
    max_characters: 3000,
    include_html_tags: true
  }
)

# AI-powered summaries
results = client.search("climate change",
  summary: {
    query: "What are the main points?"
  }
)

# Context for RAG pipelines
results = client.search("kubernetes",
  context: {
    max_characters: 5000
  }
)

# Subpage crawling
results = client.search("documentation",
  subpages: 1,
  subpage_target: ["about", "docs", "guide"]
)

# Links and image extraction
results = client.search("web development",
  extras: {
    links: 3,
    image_links: 2
  }
)

# Combine multiple features
results = client.search("AI",
  num_results: 5,
  start_published_date: "2025-01-01T00:00:00.000Z",
  text: { max_characters: 3000 },
  summary: { query: "Main developments?" },
  context: { max_characters: 5000 },
  subpages: 1,
  subpage_target: ["research"],
  extras: { links: 3, image_links: 2 }
)

# Access extracted content
results.results.each do |result|
  puts result["title"]
  puts result["text"] if result["text"]        # Full webpage text
  puts result["summary"] if result["summary"]  # AI summary
  puts result["links"] if result["links"]      # Extracted links
end
```

### Answer Command

Generate comprehensive answers to questions using Exa's answer generation feature:

```bash
# Basic question
exa-ai answer "What is the capital of France?"

# Get answer with source citations
exa-ai answer "Latest developments in quantum computing"

# Include full text from sources
exa-ai answer "Ruby on Rails best practices" --text

# Pretty formatted output
exa-ai answer "How do I learn machine learning?" --output-format pretty
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
exa-ai context "authentication with JWT"

# With custom token allocation
exa-ai context "React hooks" --tokens-num 5000

# Text output
exa-ai context "async/await patterns" --output-format text
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
exa-ai get-contents "https://example.com/article"

# Multiple pages (comma-separated)
exa-ai get-contents "https://site1.com,https://site2.com"

# With options
exa-ai get-contents "id1,id2,id3" \
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
exa-ai research-start --instructions "Find Ruby performance tips"

# Start and wait for completion
exa-ai research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4 \
  --wait

# With output schema
exa-ai research-start \
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
exa-ai research-get abc-123

# With events
exa-ai research-get abc-123 --events

# Pretty output
exa-ai research-get abc-123 --output-format pretty
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
exa-ai research-list

# With pagination
exa-ai research-list --limit 20

# Next page
exa-ai research-list --cursor "next_page_cursor"

# Pretty table format
exa-ai research-list --output-format pretty
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
- `exa-ai --version` - Show version
- `exa-ai --help` - Show available commands

### Output Formats

**JSON (default)**
```bash
exa-ai search "ruby" --output-format json
# Returns formatted JSON object
```

**Pretty**
```bash
exa-ai search "ruby" --output-format pretty
# Returns human-readable format with titles, URLs, scores
```

**Text**
```bash
exa-ai context "React" --output-format text
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
