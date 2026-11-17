# CLI Command Reference

Complete reference for the `exa-ai` command-line interface.

## Table of Contents

- [Global Options](#global-options)
- [search](#search)
- [answer](#answer)
- [find-similar (deprecated)](#find-similar-deprecated)
- [context (deprecated)](#context-deprecated)
- [get-contents](#get-contents)
- [search-monitor](#search-monitor)
- [Output Formats](#output-formats)

## Global Options

All commands support these options:

- `--api-key KEY` - Override API key from environment
- `--output-format FORMAT` - json, pretty, or text (varies by command)
- `--help, -h` - Show command help
- `exa-ai --version` - Show version
- `exa-ai --help` - Show available commands

## search

Search the web using fast or deep search.

### Basic Usage

```bash
exa-ai search "ruby programming"
exa-ai search "machine learning" --num-results 10
exa-ai search "AI" --type deep
```

### Filtering Options

```bash
# Include specific domains
exa-ai search "tutorials" --include-domains "github.com,dev.to"

# Exclude specific domains
exa-ai search "programming" --exclude-domains "outdated-site.com"

# Combine filters
exa-ai search "Python" \
  --include-domains "github.com" \
  --exclude-domains "reddit.com"
```

### Date Filtering

```bash
# Filter by published date
exa-ai search "AI research" \
  --start-published-date "2025-01-01T00:00:00.000Z" \
  --end-published-date "2025-12-31T23:59:59.999Z"

# Filter by crawl date (deprecated: the API ignores these and returns a warning)
exa-ai search "news" \
  --start-crawl-date "2025-10-01T00:00:00.000Z" \
  --end-crawl-date "2025-10-31T23:59:59.999Z"
```

### Text Filtering (deprecated)

`--include-text` and `--exclude-text` are deprecated. They still work, and matching is approximate (word-level, not exact phrase).

```bash
# Must include phrase
exa-ai search "machine learning" --include-text "neural networks"

# Must exclude phrase
exa-ai search "programming" --exclude-text "paid-partnership"

# Combine inclusion and exclusion
exa-ai search "Python" \
  --include-text "open source" \
  --exclude-text "deprecated"
```

### Content Extraction

```bash
# Extract full webpage text
exa-ai search "Ruby" --text

# With character limit
exa-ai search "AI" --text --text-max-characters 3000

# Include HTML tags in text
exa-ai search "web" --text --include-html-tags

# Generate AI summaries
exa-ai search "climate change" \
  --summary \
  --summary-query "What are the main points?"

# Format as LLM context (deprecated: use --highlights or --text)
exa-ai search "kubernetes" \
  --context \
  --context-max-characters 5000

# Crawl subpages: --subpages is deprecated on search, so send the result URLs to get-contents
exa-ai get-contents "https://ruby-lang.org" \
  --subpages 1 \
  --subpage-target about \
  --subpage-target docs

# Extract links
exa-ai search "web development" \
  --links 3 \
  --image-links 2
```

### Output Options

```bash
# Pretty format (human-readable)
exa-ai search "ruby" --output-format pretty

# JSON format (default)
exa-ai search "ruby" --output-format json
```

### Options Summary

- `QUERY` - Search query (required)
- `--num-results N` - Number of results (default: 10)
- `--type TYPE` - Search type: auto (default), lite, deep-lite, deep. Legacy: fast and instant (use lite), deep-reasoning (use deep), neural (still accepted, not in the spec)
- `--category CAT` - company, publication, news, personal site, people, or financial report. `github` is not in the spec and is rejected
- `--include-domains DOMAINS` - Comma-separated domains
- `--exclude-domains DOMAINS` - Comma-separated domains
- `--start-published-date DATE` - ISO 8601 date string
- `--end-published-date DATE` - ISO 8601 date string
- `--start-crawl-date DATE` - Deprecated. The API ignores it and returns a warning
- `--end-crawl-date DATE` - Deprecated. The API ignores it and returns a warning
- `--include-text TEXT` - Deprecated. Phrase to include (approximate match)
- `--exclude-text TEXT` - Deprecated. Phrase to exclude (approximate match)
- `--text` - Include full webpage text
- `--text-max-characters N` - Limit text length
- `--include-html-tags` - Keep HTML tags in text
- `--summary` - Include AI summary
- `--summary-query QUERY` - Custom summary query
- `--context` - Deprecated. Use `--highlights` or `--text`
- `--context-max-characters N` - Deprecated. Limit context length
- `--subpages N` - Deprecated on search. Use `exa-ai get-contents --subpages`
- `--subpage-target TARGET` - Deprecated on search. Use `exa-ai get-contents --subpage-target`
- `--highlights-num-sentences N` - Deprecated. Use `--highlights-max-characters`
- `--highlights-per-url N` - Deprecated. The API ignores it
- `--links N` - Number of links to extract
- `--image-links N` - Number of image links to extract
- `--output-format FORMAT` - json or pretty

## answer

Generate comprehensive answers to questions with source citations.

### Basic Usage

```bash
exa-ai answer "What is the capital of France?"
exa-ai answer "Latest developments in quantum computing"
```

### With Text Content

```bash
# Include full text from source pages
exa-ai answer "Ruby on Rails best practices" --text
```

### Output Options

```bash
# Pretty format
exa-ai answer "How do I learn machine learning?" --output-format pretty

# JSON format (default)
exa-ai answer "What is AI?" --output-format json
```

### Options Summary

- `QUERY` - Question to answer (required)
- `--text` - Include full text content from sources
- `--output-format FORMAT` - json or pretty (default: json)

### Response Fields

- `answer` - The generated answer
- `citations` - Array of source citations with URLs
- `cost_dollars` - Cost of the request

## find-similar (deprecated)

The API marks `/findSimilar` as deprecated. `exa-ai find-similar` still works. Use `exa-ai search` with a query that describes the source page instead. Its `--start-crawl-date`, `--end-crawl-date`, `--include-text` and `--exclude-text` flags are deprecated as on `search`.

```bash
exa-ai find-similar "https://arxiv.org/abs/2307.06435" --num-results 5
exa-ai find-similar "https://arxiv.org/abs/2307.06435" --highlights --highlights-query "key findings" --links 3
```

`find-similar` takes the same Content Extraction flags as `search`: `--text`, `--text-max-characters`, `--text-verbosity`, `--include-html-tags`, `--summary`, `--summary-query`, `--summary-schema`, `--context`, `--context-max-characters`, `--subpages`, `--subpage-target`, `--links`, `--image-links`, `--highlights`, `--highlights-max-characters`, `--highlights-num-sentences`, `--highlights-per-url`, `--highlights-query`, `--livecrawl`, `--livecrawl-timeout`, `--max-age-hours` and `--snapshot-as-of`. They go under `contents` in the request. `--highlights-query` and the other `--highlights-*` flags have an effect only with `--highlights`. The search-only flags, such as `--type` and `--output-schema`, are not available.

## context (deprecated)

`/context` is not in the Exa API spec. `exa-ai context` still works, but no replacement is named. For code lookup, use `exa-ai search`.

Find relevant code snippets and documentation from repositories.

### Basic Usage

```bash
exa-ai context "authentication with JWT"
exa-ai context "React hooks"
exa-ai context "async/await patterns"
```

### Token Allocation

```bash
# Fixed token count
exa-ai context "React hooks" --tokens-num 5000

# Dynamic allocation (default)
exa-ai context "authentication" --tokens-num dynamic
```

### Output Options

```bash
# Text format
exa-ai context "async/await" --output-format text

# JSON format (default)
exa-ai context "authentication" --output-format json
```

### Options Summary

- `QUERY` - Search query (required)
- `--tokens-num NUM` - Token allocation: integer or "dynamic" (default: dynamic)
- `--output-format FORMAT` - json or text (default: json)

## get-contents

Retrieve full text content from web pages.

### Single Page

```bash
exa-ai get-contents "https://example.com/article"
```

### Multiple Pages

```bash
# Comma-separated URLs
exa-ai get-contents "https://site1.com,https://site2.com,https://site3.com"
```

### With Options

```bash
# Include full text
exa-ai get-contents "https://example.com" --text

# Include highlighted sections
exa-ai get-contents "https://example.com" --highlights

# Include summary
exa-ai get-contents "https://example.com" --summary

# Combine options
exa-ai get-contents "url1,url2" \
  --text \
  --highlights \
  --summary
```

### Output Options

```bash
# Pretty format
exa-ai get-contents "https://example.com" --output-format pretty

# JSON format (default)
exa-ai get-contents "https://example.com" --output-format json
```

### Options Summary

- `IDS` - Page IDs or URLs (required, comma-separated)
- `--text` - Include full text content
- `--highlights` - Include highlighted sections
- `--summary` - Include summary
- `--context` - Deprecated. Use `--highlights` or `--text`
- `--output-format FORMAT` - json or pretty (default: json)


## search-monitor

Search monitors run an Exa search on a schedule and post new results to a webhook (the `/monitors` API). Each command has its own executable, `exa-ai-search-monitor-<command>`, and `exa-ai search-monitor-<command>` runs the same thing. All take `--api-key`, `--output-format json|pretty|text|toon` and `--help`.

| Command | Arguments and options |
|---|---|
| `search-monitor-create` | `--query TEXT` and `--webhook-url URL` (required); `--period 1d`, `--name`, `--num-results`, `--include-domains a,b`, `--exclude-domains a,b`, `--webhook-events a,b`, `--output-schema JSON\|@file`, `--metadata JSON\|@file` |
| `search-monitor-list` | `--status`, `--name`, `--limit`, `--cursor` |
| `search-monitor-get` | `ID` |
| `search-monitor-update` | `ID`; `--name`, `--status active\|paused`, `--query`, `--period`, `--remove-trigger`, `--webhook-url`, `--webhook-events`, `--output-schema`, `--metadata` |
| `search-monitor-delete` | `ID` |
| `search-monitor-trigger` | `ID` (runs the monitor now) |
| `search-monitor-batch` | `--action delete\|pause\|unpause` (required); filter `--status`, `--name`, `--metadata JSON`; `--limit`; `--execute` |
| `search-monitor-runs-list` | `MONITOR_ID`; `--limit`, `--cursor` |
| `search-monitor-runs-get` | `MONITOR_ID RUN_ID` |

Without `--period`, a monitor runs only when you call `search-monitor-trigger`. The create response holds the webhook secret, which the API returns only once. `search-monitor-batch` is a dry run unless you pass `--execute`.

```bash
exa-ai-search-monitor-create --query "AI/ML infrastructure startups with Series A funding" \
  --webhook-url https://your-app.example/webhooks/exa --period 1d --output-format pretty
exa-ai-search-monitor-batch --action pause --status active            # dry run
exa-ai-search-monitor-batch --action pause --status active --execute  # apply
```

## Output Formats

### JSON Format

Default output format returns structured JSON:

```bash
exa-ai search "ruby" --output-format json
# Returns: {"results": [...], "cost_dollars": ...}
```

### Pretty Format

Human-readable format with formatted titles and URLs:

```bash
exa-ai search "ruby" --output-format pretty
# Returns nicely formatted output for terminal display
```

### Text Format

Plain text output (available for context command):

```bash
exa-ai context "React" --output-format text
# Returns plain text output
```
