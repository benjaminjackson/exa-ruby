# Ruby API Reference

Complete reference for the Exa Ruby client library.

## Table of Contents

- [Client Initialization](#client-initialization)
- [Search](#search)
- [Answer](#answer)
- [Context](#context)
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
  type: "deep",           # fast, deep, keyword, or auto (default: fast)
  include_domains: ["arxiv.org", "github.com"],
  exclude_domains: ["example.com"]
)
```

### Advanced: Date Filtering

```ruby
results = client.search("AI research",
  start_published_date: "2025-01-01T00:00:00.000Z",
  end_published_date: "2025-12-31T23:59:59.999Z"
)

# Filter by crawl date
results = client.search("news",
  start_crawl_date: "2025-10-01T00:00:00.000Z",
  end_crawl_date: "2025-10-31T23:59:59.999Z"
)
```

### Advanced: Text Filtering

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

### Advanced: RAG Context

```ruby
results = client.search("kubernetes",
  context: {
    max_characters: 5000
  }
)

results.results.each do |result|
  puts result["context"]
end
```

### Advanced: Subpage Crawling

```ruby
results = client.search("documentation",
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
  context: { max_characters: 5000 },
  subpages: 1,
  subpage_target: ["research"],
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

### Answer with Text Content

```ruby
answer = client.answer("Latest AI breakthroughs", text: true)
puts answer.answer

answer.citations.each do |citation|
  puts "#{citation["title"]} (#{citation['url']})"
end
```

## Context

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
  text: true,
  highlights: true,
  summary: true
)
```

## Search Monitors

A search monitor runs an Exa search on a schedule and posts new results to a webhook (`/monitors`). It is a different product from Websets monitors (`create_monitor`, `list_monitors`).

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
