# Ruby API Reference

Complete reference for the Exa Ruby client library.

## Table of Contents

- [Client Initialization](#client-initialization)
- [Search](#search)
- [Answer](#answer)
- [Context](#context)
- [Get Contents](#get-contents)
- [Research](#research)

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

## Research

Start and manage long-running research tasks.

### Start a Research Task

```ruby
task = client.research_start(
  instructions: "Analyze recent AI breakthroughs",
  model: "gpt-4"
)
puts task.research_id  # Save for later polling
```

### With Output Schema

```ruby
task = client.research_start(
  instructions: "Extract key metrics",
  output_schema: {
    format: "json",
    fields: ["metric", "value"]
  }
)
```

### Check Task Status

```ruby
status = client.research_get(task.research_id)
puts status.status     # pending, completed, failed
puts status.output if status.completed?
```

### List All Tasks

```ruby
list = client.research_list(limit: 20)
list.data.each do |task|
  puts "#{task.research_id}: #{task.status}"
end

# With pagination
list = client.research_list(limit: 20, cursor: "next_cursor")
```

## Response Objects

The API returns wrapped response objects with convenient accessor methods:

- `SearchResult` - Wraps search results
- `AnswerResult` - Wraps answer and citations
- `ContextResult` - Wraps code context
- `ContentsResult` - Wraps page contents
- `ResearchTask` - Wraps research task information
- `ResearchList` - Wraps paginated research tasks

All response objects provide `#to_h` for serialization to plain hashes.

## Error Handling

See the main README for error handling examples and exception hierarchy.
