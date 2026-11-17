# exa-ruby

Ruby client for the Exa.ai API. Search and analyze web content using neural search, question answering, code discovery, and agent-based research.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Features](#features)
- [Agent](#agent)
- [Search Monitors](#search-monitors)
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

# Find similar content (deprecated: prefer search with a query that describes the page)
similar = client.find_similar("https://arxiv.org/abs/2307.06435")
similar.results.each { |item| puts item['url'] }

# Get an answer to a question
answer = client.answer("What is machine learning?")
puts answer.answer

# Find code examples (deprecated: /context is not in the API spec)
code = client.context("React hooks")
puts code.response

# Get page contents
contents = client.get_contents(["https://ruby-lang.org"])
puts contents.results.first["text"]

# Stream a search with a synthesized answer (requires output_schema)
schema = { type: "object", properties: { summary: { type: "string" } } }
client.search_stream("Ruby 3.4 release highlights", output_schema: schema) do |chunk|
  print chunk["delta"] if chunk["type"] == "text-delta"
end
```

### Command Line

```bash
# Core Search Commands
exa-ai search "Ruby programming language"
exa-ai find-similar "https://arxiv.org/abs/2307.06435"   # deprecated
exa-ai answer "What is machine learning?"
exa-ai context "React hooks" --tokens-num 5000          # deprecated
exa-ai get-contents "https://ruby-lang.org"
exa-ai search "climate tech seed rounds" --type lite --objective "Find primary sources"
exa-ai get-contents --ids DOC_ID_1,DOC_ID_2 --highlights --highlights-verbosity low
exa-ai answer "What is machine learning?" --model exa-pro --user-location US

# Print the JSON request body sent to the API as one line on stderr. A
# deprecation warning for each deprecated flag comes before it; API warnings
# and error messages come after it. Results still go to stdout
exa-ai search "AI/ML infrastructure startups with Series A funding" --print-request 2>stderr.log

# Stop with an error, and send no request, when a deprecated flag is given
exa-ai search "venture-backed SaaS companies" --livecrawl --strict
```

## Features

The gem provides complete access to Exa's API endpoints:

### Core Search
- **Search** — Neural and keyword search across billions of web pages
- **Find Similar** (deprecated) — Discover content similar to a given URL
- **Answer** — Generate comprehensive answers with source citations
- **Context** (deprecated) — Find relevant code and documentation snippets
- **Get Contents** — Extract full text content from web pages

### Deprecated and legacy options

These still work, so existing code keeps running. The search command prints the API's `warnings` to stderr when the API flags one of them. Use the replacement in new code.

`exa-ai search` and `exa-ai get-contents` print one line on stderr for each deprecated flag you give, before the request is sent: `Warning: --livecrawl is deprecated; use --max-age-hours 0 --livecrawl-timeout 5000`. When a flag has no replacement, the line gives the reason. stdout does not change. Add `--strict` to make each line an `Error:` line: the command exits 1 and sends no request. With `--print-request`, the warnings come before the request body; with `--strict` and a deprecated flag, no body is printed. `exa-ai find-similar` does not warn and does not take `--strict`.

- `find_similar` / `exa-ai find-similar`: deprecated by the API. Use `search` with a query that describes the source page.
- `context` / `exa-ai context`: `/context` is not in the API spec. No replacement is named; for code lookup, use `search`.
- Search types `fast` and `instant` are legacy; use `lite`. `deep-reasoning` is legacy; use `deep`.
- `start_crawl_date` and `end_crawl_date` are deprecated. The API ignores them.
- `include_text` and `exclude_text` are deprecated.
- The `context` contents option and the `context` response field are deprecated. Use `highlights` or `text`.
- `highlights` `num_sentences` and `highlights_per_url` are deprecated. Use `max_characters`.
- `subpages` and `subpage_target` are deprecated on `search` and `find_similar`. They stay valid on `get_contents`.
- `exa-ai search --livecrawl` and `exa-ai find-similar --livecrawl` are deprecated. Use `--max-age-hours 0 --livecrawl-timeout 5000`, which sends the same request.
- The `resolved_search_type` response field is deprecated.
- The CLI no longer accepts `--category github`; it is not in the API's category list.

See [docs/API.md](docs/API.md) and [docs/CLI.md](docs/CLI.md) for details.

### Flag list for wrappers

`exa-ai search --flags-json` and `exa-ai get-contents --flags-json` print every flag the command accepts as a JSON array, then exit 0. They need no API key and send no request. The output is the same with a query or other flags on the command line.

The same data is in Ruby constants:

```ruby
require "exa"
require "exa/cli/search_parser"
require "exa/cli/get_contents"

Exa::CLI::SearchParser::FLAGS  # exa-ai search
Exa::CLI::GetContents::FLAGS   # exa-ai get-contents
```

Each entry has these keys, in this order:

```json
{"flag":"--highlights-num-sentences","api_field":"contents.highlights.numSentences","deprecated":true,"replacement":"--highlights-max-characters","reason":null}
```

- `flag`: the flag name. The short alias `-h` is not listed.
- `api_field`: the request body field the flag sets, as sent (camelCase, dotted path). It is `null` when the flag sets no field (`--api-key`, `--output-format`), and an array when the flag sets more than one (`--livecrawl`).
- `deprecated`: `true` when the help text marks the flag deprecated.
- `replacement`: what to type instead of a deprecated flag. It can be a phrase, such as `--max-age-hours 0 --livecrawl-timeout 5000`. It is `null` when there is no replacement.
- `reason`: why a deprecated flag with no replacement is deprecated, such as `the API ignores it`. It is `null` for every other flag. A deprecated flag always has a `replacement` or a `reason`.

The commands reject any flag that is not in their list. The constants and the `--flags-json` output are public API: wrappers can rely on them instead of reading the gem's source.

### Agent
- **Agent API** — Asynchronous research agent with citations, streaming, and full run lifecycle

## Agent

Exa's Agent API runs asynchronous research agents that search the web, synthesize findings, and return structured output with source citations. Runs are long-lived — create one, poll for completion, and stream events as it progresses. Exa retired the Research API; the Agent API (`exa-ai agent-run-create` and related commands) is its replacement. Pass your prompt as `--query` (Ruby: `query:`), not `--instructions`.

### Ruby API

```ruby
require 'exa-ai'

client = Exa::Client.new(api_key: ENV['EXA_API_KEY'])

# Create an async agent run
run = client.agent_run_create(
  query: "AI infrastructure startups that raised Series A in 2025",
  effort: "high"
)
puts run.id      # => "run_abc123"
puts run.status  # => "queued"
puts run.queued? # => true

# Poll for the result
run = client.agent_run_get(run.id)
if run.completed?
  puts run.output[:text]
  puts run.output[:structured]  # already-parsed JSON — no string parsing needed
  puts run.output[:grounding]
end

# Create a run with structured output and a system prompt
run = client.agent_run_create(
  query: "AI infrastructure startups that raised Series A in 2025",
  system_prompt: "Return only companies headquartered in the US.",
  effort: "high",
  output_schema: {
    type: "object",
    properties: {
      companies: { type: "array", items: { type: "string" } }
    }
  }
)

# Attach premium data partners (Exa Connect) alongside web search.
# The agent queries each partner where it's strongest and blends the
# results into one grounded, structured answer.
run = client.agent_run_create(
  query: "Profile Anthropic: total funding and estimated monthly web traffic",
  data_sources: [{ provider: "fiber" }, { provider: "similarweb" }],
  output_schema: {
    type: "object",
    properties: {
      name: { type: "string" },
      totalFunding: { type: "string" },  # from Fiber.ai
      monthlyVisits: { type: "number" }  # from Similarweb
    }
  }
)

# Limit what a run may spend. max_cost_dollars accepts $1 to $100;
# max_duration_seconds (300 to 10800) applies only to effort "ultra".
run = client.agent_run_create(
  query: "Every public company that announced a lithium recycling plant in 2025",
  effort: "ultra",
  budget: { max_cost_dollars: 20.0, max_duration_seconds: 3600 }
)

# Stream events as they arrive
client.agent_run_stream(query: "AI infrastructure startups that raised Series A in 2025") do |event, data, event_id|
  puts "#{event} (#{event_id}): #{data.inspect}"
  # event is the SSE event-type string, e.g. "agent_run.completed"
  # data is the parsed JSON hash; event_id is the SSE id, or nil
end

# List recent runs
runs = client.agent_run_list(limit: 5)
puts runs.has_more    # => true/false
puts runs.next_cursor # => pagination cursor
runs.data.each { |r| puts "#{r.id}: #{r.status}" }

# Fetch a run's events
events = client.agent_run_events(run.id)

# Replay the events after a known event id (server-sent events).
# This reads the whole response before it returns.
events = client.agent_run_events(run.id, last_event_id: "7")

# Stop a run early: it completes with stop_reason "stopped" and keeps the
# results gathered so far (effort high, xhigh or ultra only)
client.agent_run_stop(run.id)

# Cancel a run (it ends at once with no results), or delete it
client.agent_run_cancel(run.id)
deletion = client.agent_run_delete(run.id) # => Exa::Resources::AgentRunDeletion
deletion.deleted? # => true
```

> **Note:** The gem converts snake_case keys to camelCase at every depth, including keys inside `input` and `data_sources` items. Keys under `output_schema`, `schema`, `metadata`, `data` and `exclusion` are your own data and are sent unchanged, so supply them in the exact shape the API expects.

### Command Line

```bash
# Create a run and wait for it to finish
exa-ai agent-run-create --query "AI infrastructure startups that raised Series A in 2025" --wait --output-format pretty

# Attach premium data partners (Exa Connect) with a structured schema.
# Run `exa-ai agent-run-create --help` to see every provider and when to use it:
# fiber, similarweb, baselayer, polymarket, macrobond, affiliate, particle,
# financial_datasets, jinko (up to 5 per run)
exa-ai agent-run-create --wait \
  --query "Profile Anthropic: total funding and monthly web traffic" \
  --data-sources fiber,similarweb \
  --output-schema '{"type":"object","properties":{"name":{"type":"string"},"totalFunding":{"type":"string"},"monthlyVisits":{"type":"number"}}}'

# Cap cost and time for an ultra run
exa-ai agent-run-create --effort ultra --max-cost-dollars 20 --max-duration-seconds 3600 \
  --query "Every public company that announced a lithium recycling plant in 2025"

# Fetch an existing run
exa-ai agent-run-get <run_id>

# List recent runs
exa-ai agent-run-list --limit 5

# Stop a run early and keep its results, or cancel or delete it
exa-ai agent-run-stop <run_id>
exa-ai agent-run-cancel <run_id>
exa-ai agent-run-delete <run_id>

# Fetch a run's events, one page at a time
exa-ai agent-run-events <run_id> --limit 50
exa-ai agent-run-events <run_id> --limit 50 --cursor <next_cursor>
```

## Search Monitors

A search monitor runs an Exa search on a schedule and posts new results to your webhook. This is the Monitors API (`/monitors`).

### Ruby API

```ruby
client = Exa::Client.new(api_key: "your-key")

# Create a monitor that runs once a day.
# Without trigger:, the monitor runs only when you call search_monitor_trigger.
monitor = client.search_monitor_create(
  name: "AI funding news",
  search: { query: "AI/ML infrastructure startups with Series A funding", num_results: 10 },
  webhook: { url: "https://your-app.example/webhooks/exa" },
  trigger: { type: "interval", period: "1d" }
)
monitor.webhook_secret # The API returns this only once. Store it now.

client.search_monitor_get(monitor.id)
client.search_monitor_list(status: "active", limit: 20)
client.search_monitor_update(monitor.id, status: "paused")
client.search_monitor_update(monitor.id, trigger: nil) # remove the schedule
client.search_monitor_trigger(monitor.id)              # run now

runs = client.search_monitor_runs_list(monitor.id)
client.search_monitor_runs_get(monitor.id, runs.data.first.id)

# Pause, unpause or delete many monitors. This is a dry run unless you pass dry_run: false.
result = client.search_monitor_batch(action: "pause", filter: { name: "AI funding" })
result.ids # what would change

client.search_monitor_delete(monitor.id)
```

### Command Line

```bash
exa-ai search-monitor-create --query "AI/ML infrastructure startups with Series A funding" \
  --webhook-url https://your-app.example/webhooks/exa --period 1d --name "AI funding news"
exa-ai search-monitor-list --status active
exa-ai search-monitor-get <monitor_id>
exa-ai search-monitor-update <monitor_id> --status paused
exa-ai search-monitor-trigger <monitor_id>
exa-ai search-monitor-runs-list <monitor_id>
exa-ai search-monitor-runs-get <monitor_id> <run_id>
exa-ai search-monitor-batch --action pause --name "AI funding"            # dry run
exa-ai search-monitor-batch --action pause --name "AI funding" --execute  # apply
exa-ai search-monitor-delete <monitor_id>
```

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
```

### Integration Tests

**Integration tests are skipped by default** to prevent accidental API calls.

**VCR-based integration tests (`RUN_INTEGRATION_TESTS`):**
- Use recorded HTTP interactions (VCR cassettes)
- No real API calls when replaying cassettes
- Set `RUN_INTEGRATION_TESTS=true` to run them
- Safe to run during development

**When to run integration tests:**
- VCR tests: Anytime (safe, no real API calls)

**Test Coverage:**
- **Unit tests** - Fast, no API calls, always run
- **VCR integration tests** - Replay cassettes, skipped by default

## Support

- **Documentation**: https://docs.exa.ai
- **Dashboard**: https://dashboard.exa.ai
- **Status**: https://status.exa.ai

## License

MIT License - See [LICENSE](LICENSE) file for details

---

**Built with [Exa.ai](https://exa.ai)** — The search and discovery API
