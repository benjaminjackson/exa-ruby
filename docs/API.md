# Ruby API Reference

Complete reference for the Exa Ruby client library.

## Table of Contents

- [Client Initialization](#client-initialization)
- [Search](#search)
- [Answer](#answer)
- [Find Similar (deprecated)](#find-similar-deprecated)
- [Context (deprecated)](#context-deprecated)
- [Get Contents](#get-contents)
- [Search Monitors](#search-monitors)

## Client Initialization

```ruby
require 'exa-ai'

# Using configuration
Exa.configure do |config|
  config.api_key = ENV['EXA_API_KEY']
end
client = Exa::Client.new

# Or pass API key directly
client = Exa::Client.new(api_key: "your-api-key")
```

## Search

Search the web using fast or deep search.

### Basic Search

```ruby
results = client.search("machine learning")
results.results.each do |item|
  puts item["title"]
  puts item["url"]
  puts item["score"]
end
```

### Search with Options

```ruby
results = client.search("AI",
  num_results: 10,
  type: "deep",           # auto (default), lite, deep-lite, deep; legacy: fast, instant, deep-reasoning, neural
  include_domains: ["arxiv.org", "github.com"],
  exclude_domains: ["example.com"]
)
```

`lite` accepts only a limited set of parameters, and the API rejects a request that sets any other. See https://exa.ai/docs/search/quickstart.md#lite.

### Deprecated and Legacy Options

These options still work. The API reports some of them in the response's `warnings`. Use the replacement in new code.

| Option | Status | Use instead |
| --- | --- | --- |
| `type: "fast"`, `type: "instant"` | Legacy | `type: "lite"` |
| `type: "deep-reasoning"` | Legacy | `type: "deep"` |
| `start_crawl_date`, `end_crawl_date` | Deprecated. The API ignores them and adds an `IGNORED_FIELD` warning. | None; leave them out |
| `include_text`, `exclude_text` | Deprecated | No replacement named in the spec |
| `context` | Deprecated | `highlights` or `text` |
| `highlights: { num_sentences: }` | Deprecated | `highlights: { max_characters: }` |
| `highlights: { highlights_per_url: }` | Deprecated. The API ignores it. | `highlights: { max_characters: }` |
| `subpages`, `subpage_target` on `search` | Deprecated | Pass them to `get_contents` |
| `livecrawl` | Deprecated | `max_age_hours` |
| `crawled_before_date` | Deprecated. An alias of `snapshot_as_of` with identical behavior. | `snapshot_as_of` |
| `category: "github"` | Not in the spec's category list. The CLI rejects it; the Ruby client still sends it. | Another category, or none |

On the result, `resolved_search_type` is deprecated (it may be an empty string), `search_type` is not in the spec, and `context` is deprecated.

### Request Options from the Spec

```ruby
results = client.search("coffee near me",
  objective: "Find independent cafes open now",
  user_identifier: "user_42",               # opaque ID, no personal data
  compliance: "hipaa",                      # enterprise only
  user_location: { country: "US", latitude: 37.77, longitude: -122.42 },
  snapshot_as_of: "2026-01-01T00:00:00Z",   # goes under contents
  text: { link_style: "citation" },
  extras: { rich_image_links: 3 }
)
```

### Warnings, Notices and Search Time

```ruby
results = client.search("climate tech seed rounds", type: "lite")
results.warnings     # [{"code", "path", "message"}] - for your logs, not for a model
results.notices      # [{"code", "path", "message", "details"}] - written for a model
results.search_time  # milliseconds
```

The CLI prints warnings to stderr and shows notices in `pretty` and `text` output.

### Dynamic Highlights

```ruby
results = client.search("AI chip export rules", highlights: { dynamic: true, verbosity: "low" })
```

When a request sets `highlights.dynamic` or `highlights.verbosity`, the gem sends the header `Exa-Beta: dynamic-highlights-2026-08-28`. The API rejects these options without it.

### Streaming Search

The API streams `/search` only when `output_schema` is set, so `search_stream` requires it.

```ruby
schema = { type: "object", properties: { lead_investor: { type: "string" } } }
client.search_stream("Who led the latest Anthropic funding round?", output_schema: schema) do |chunk|
  case chunk["type"]
  when "text-delta" then print chunk["delta"]
  when "results" then puts chunk["results"].size
  end
end
```

Each chunk is a Hash with a `type` of `text-delta`, `grounding`, `results`, `stream-reset` or `done`. An `error` chunk raises `Exa::Error`.

### Advanced: Date Filtering

```ruby
results = client.search("AI research",
  start_published_date: "2025-01-01T00:00:00.000Z",
  end_published_date: "2025-12-31T23:59:59.999Z"
)

# Filter by crawl date (deprecated: the API ignores these and returns a warning)
results = client.search("news",
  start_crawl_date: "2025-10-01T00:00:00.000Z",
  end_crawl_date: "2025-10-31T23:59:59.999Z"
)
```

### Advanced: Text Filtering (deprecated)

`include_text` and `exclude_text` are deprecated. They still work, and matching is approximate (word-level, not exact phrase).

```ruby
results = client.search("machine learning",
  include_text: ["neural networks"],
  exclude_text: ["cryptocurrency"]
)
```

### Advanced: Text Extraction

```ruby
# Extract full webpage text
results = client.search("Ruby",
  text: {
    max_characters: 3000,
    include_html_tags: true
  }
)

# Access text in results
results.results.each do |result|
  puts result["text"]
end
```

### Advanced: AI Summaries

```ruby
results = client.search("climate change",
  summary: {
    query: "What are the main points?"
  }
)

results.results.each do |result|
  puts result["summary"]
end
```

### Advanced: RAG Context (deprecated)

`context` is deprecated. Use `highlights` or `text` instead.

```ruby
results = client.search("kubernetes",
  context: {
    max_characters: 5000
  }
)

puts results.context
```

### Advanced: Subpage Crawling (deprecated on search)

`subpages` and `subpage_target` are deprecated on `search` and `find_similar`. They stay valid on `get_contents`: send the result URLs there instead.

```ruby
contents = client.get_contents(["https://ruby-lang.org"],
  subpages: 1,
  subpage_target: ["about", "docs", "guide"]
)
```

### Advanced: Link Extraction

```ruby
results = client.search("web development",
  extras: {
    links: 3,
    image_links: 2
  }
)

results.results.each do |result|
  puts result["links"]      # Array of extracted links
  puts result["image_links"] # Array of extracted image links
end
```

### Combining Multiple Features

```ruby
results = client.search("AI",
  num_results: 5,
  start_published_date: "2025-01-01T00:00:00.000Z",
  text: { max_characters: 3000 },
  summary: { query: "Main developments?" },
  highlights: { max_characters: 2000 },
  extras: { links: 3, image_links: 2 }
)
```

## Answer

Generate comprehensive answers to questions with source citations.

### Basic Answer

```ruby
answer = client.answer("What are the best practices for API design?")
puts answer.answer        # The generated answer
puts answer.citations     # Array of source citations
puts answer.cost_dollars  # API cost
```

### Answer Model and End User

```ruby
answer = client.answer("What is the latest valuation of SpaceX?",
  model: "exa-pro",               # exa (default), exa-pro, exa-research, exa-fast
  user_location: "US",
  user_identifier: "user_42"
)
answer.request_id
```

On the command line: `exa-ai answer QUERY --model exa-pro --user-location US --user-identifier user_42`.

### Answer with Text Content

```ruby
answer = client.answer("Latest AI breakthroughs", text: true)
puts answer.answer

answer.citations.each do |citation|
  puts "#{citation["title"]} (#{citation['url']})"
end
```

## Find Similar (deprecated)

The API marks `/findSimilar` as deprecated. `client.find_similar` still works. Use `client.search` with a query that describes the source page instead.

```ruby
similar = client.find_similar("https://arxiv.org/abs/2307.06435", num_results: 5)
```

## Context (deprecated)

`/context` is not in the Exa API spec. `client.context` still works, but no replacement is named. For code lookup, use `client.search`.

Find relevant code snippets and documentation from repositories.

### Basic Context Search

```ruby
code = client.context("authentication in Rails")
puts code.response        # The code context
puts code.results_count   # Number of results
puts code.cost_dollars    # API cost
```

### Context with Token Allocation

```ruby
# Fixed token count
code = client.context("React hooks", tokens_num: 5000)

# Dynamic token allocation (default)
code = client.context("authentication", tokens_num: "dynamic")
```

## Get Contents

Retrieve the full text content from web pages.

### Single Page

```ruby
contents = client.get_contents(["https://example.com/article"])
contents.results.each do |content|
  puts content["url"]
  puts content["title"]
  puts content["text"]
end
```

### Multiple Pages

```ruby
contents = client.get_contents([
  "https://example.com/page1",
  "https://example.com/page2",
  "https://example.com/page3"
])
```

### With Options

```ruby
contents = client.get_contents(["https://example.com"],
  text: { verbosity: "compact" },
  highlights: { query: "pricing", verbosity: "low" },
  summary: true,
  max_age_hours: 24,
  snapshot_as_of: "2026-01-01T00:00:00Z"
)
contents.search_time
```

Flat keys work here as on `search`: `text_max_characters: 3000` sends `text: { maxCharacters: 3000 }`, and `summary_schema:` sends `summary: { schema: }`.

`context` is deprecated here too; use `highlights` or `text`. In `highlights`, `num_sentences` and `highlights_per_url` are deprecated; use `max_characters`. `subpages` and `subpage_target` stay valid on `get_contents`. `livecrawl` is deprecated; use `max_age_hours`. `crawled_before_date` is deprecated; use `snapshot_as_of`, an alias with identical behavior.

### By Document ID

```ruby
contents = client.get_contents(ids: ["DOC_ID_1", "DOC_ID_2"], text: true)
```

`urls` is sent only when you pass it. On the command line: `exa-ai get-contents --ids DOC_ID_1,DOC_ID_2`.

## Search Monitors

A search monitor runs an Exa search on a schedule and posts new results to a webhook (`/monitors`).

### Create

```ruby
monitor = client.search_monitor_create(
  search: { query: "AI/ML infrastructure startups with Series A funding", num_results: 10,
            include_domains: ["techcrunch.com"] },
  webhook: { url: "https://your-app.example/webhooks/exa", events: ["monitor.run.completed"] },
  trigger: { type: "interval", period: "1d" }, # 1h minimum; omit for manual runs only
  name: "AI funding news",
  output_schema: { type: "object", properties: { company: { type: "string" } } },
  metadata: { "team" => "research" }
)
monitor.webhook_secret # returned only once
```

Keys inside `search` are converted from snake_case to camelCase the same way as for `client.search`. The values of `output_schema` and `metadata` are sent as given.

### Get, List, Update, Delete

```ruby
client.search_monitor_get("mon_abc123")
client.search_monitor_list(status: "active", name: "AI", metadata: { "team" => "research" }, limit: 20, cursor: nil)
client.search_monitor_update("mon_abc123", status: "paused")
client.search_monitor_update("mon_abc123", trigger: nil) # sends "trigger": null, which removes the schedule
client.search_monitor_delete("mon_abc123")
```

### Trigger and Runs

```ruby
client.search_monitor_trigger("mon_abc123").triggered # => true
runs = client.search_monitor_runs_list("mon_abc123", limit: 10)
run = client.search_monitor_runs_get("mon_abc123", runs.data.first.id)
run.completed? # also pending?, running?, failed?, cancelled?, finished?
```

### Batch

```ruby
result = client.search_monitor_batch(action: "delete", filter: { status: "paused" })
result.dry_run  # => true; nothing changed
result = client.search_monitor_batch(action: "delete", filter: { status: "paused" }, dry_run: false, limit: 100)
result.has_more # call again until false
```

`action` is `delete`, `pause` or `unpause`. `filter` takes `name`, `status` and `metadata`. The request is a dry run unless you pass `dry_run: false`.

Return types: `SearchMonitor` (with `active?`, `paused?`, `disabled?`), `SearchMonitorList` (also used for pages of runs), `SearchMonitorRun`, `SearchMonitorBatchResult`, `SearchMonitorTriggerResult`.

## Response Objects

The API returns wrapped response objects with convenient accessor methods:

- `SearchResult` - Wraps search results
- `AnswerResult` - Wraps answer and citations
- `ContextResult` - Wraps code context
- `ContentsResult` - Wraps page contents

All response objects provide `#to_h` for serialization to plain hashes.

## Error Handling

See the main README for error handling examples and exception hierarchy.
