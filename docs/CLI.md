# CLI Command Reference

Complete reference for the `exa-ai` command-line interface.

## Table of Contents

- [Global Options](#global-options)
- [search](#search)
- [answer](#answer)
- [context](#context)
- [get-contents](#get-contents)
- [research-start](#research-start)
- [research-get](#research-get)
- [research-list](#research-list)
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

# Filter by crawl date
exa-ai search "news" \
  --start-crawl-date "2025-10-01T00:00:00.000Z" \
  --end-crawl-date "2025-10-31T23:59:59.999Z"
```

### Text Filtering

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

# Format as LLM context
exa-ai search "kubernetes" \
  --context \
  --context-max-characters 5000

# Crawl subpages
exa-ai search "documentation" \
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
- `--type TYPE` - Search type: fast, deep, keyword, or auto (default: fast)
- `--include-domains DOMAINS` - Comma-separated domains
- `--exclude-domains DOMAINS` - Comma-separated domains
- `--start-published-date DATE` - ISO 8601 date string
- `--end-published-date DATE` - ISO 8601 date string
- `--start-crawl-date DATE` - ISO 8601 date string
- `--end-crawl-date DATE` - ISO 8601 date string
- `--include-text TEXT` - Phrase to include
- `--exclude-text TEXT` - Phrase to exclude
- `--text` - Include full webpage text
- `--text-max-characters N` - Limit text length
- `--include-html-tags` - Keep HTML tags in text
- `--summary` - Include AI summary
- `--summary-query QUERY` - Custom summary query
- `--context` - Include LLM-formatted context
- `--context-max-characters N` - Limit context length
- `--subpages N` - Number of subpages to crawl
- `--subpage-target TARGET` - Subpage URL pattern (repeatable)
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

## context

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
- `--output-format FORMAT` - json or pretty (default: json)

## research-start

Start a long-running research task.

### Basic Usage

```bash
exa-ai research-start --instructions "Find Ruby performance tips"
```

### With Model

```bash
exa-ai research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4
```

### With Output Schema

```bash
exa-ai research-start \
  --instructions "Extract key metrics" \
  --output-schema '{"format":"json","fields":["metric","value"]}'
```

### Wait for Completion

```bash
# Block until task completes
exa-ai research-start \
  --instructions "Research AI trends" \
  --wait

# Show event log while waiting
exa-ai research-start \
  --instructions "Research AI trends" \
  --wait \
  --events
```

### Output Options

```bash
# Pretty format
exa-ai research-start --instructions "..." --output-format pretty

# JSON format (default)
exa-ai research-start --instructions "..." --output-format json
```

### Options Summary

- `--instructions TEXT` - Research instructions (required)
- `--model MODEL` - Model to use (e.g., gpt-4)
- `--output-schema SCHEMA` - JSON schema for structured output
- `--wait` - Block until completion
- `--events` - Show event log during polling
- `--output-format FORMAT` - json or pretty (default: json)

## research-get

Check status of a research task.

### Basic Usage

```bash
exa-ai research-get abc-123
```

### With Event Log

```bash
exa-ai research-get abc-123 --events
```

### Stream Results (Premium)

```bash
exa-ai research-get abc-123 --stream
```

### Output Options

```bash
# Pretty format
exa-ai research-get abc-123 --output-format pretty

# JSON format (default)
exa-ai research-get abc-123 --output-format json
```

### Options Summary

- `RESEARCH_ID` - Task ID (required)
- `--events` - Include event log
- `--stream` - Stream results (premium feature)
- `--output-format FORMAT` - json or pretty (default: json)

## research-list

List research tasks with pagination.

### Basic Usage

```bash
exa-ai research-list
```

### Pagination

```bash
# Set page size
exa-ai research-list --limit 20

# Get next page
exa-ai research-list --limit 20 --cursor "next_cursor"
```

### Output Options

```bash
# Pretty table format
exa-ai research-list --output-format pretty

# JSON format (default)
exa-ai research-list --output-format json
```

### Options Summary

- `--cursor CURSOR` - Pagination cursor
- `--limit N` - Results per page (default: 10)
- `--output-format FORMAT` - json or pretty (default: json)

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
