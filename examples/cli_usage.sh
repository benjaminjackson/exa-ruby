#!/bin/bash
# CLI Usage Examples for Exa Ruby Gem
# Set your API key before running: export EXA_API_KEY="your-key"

echo "=== Exa CLI Usage Examples ==="
echo ""

# Help and version
echo "1. Getting Help"
exa-ai --help
exa-ai --version
exa-ai search --help

echo ""
echo "2. Basic Search"
exa-ai search "ruby programming"
exa-ai search "machine learning" --num-results 5

echo ""
echo "3. Search with Filtering"
exa-ai search "tutorials" \
  --include-domains "github.com,dev.to" \
  --num-results 10

exa-ai search "Python" \
  --type deep \
  --exclude-domains "old-blog.com"

echo ""
echo "4. Search with Output Format"
exa-ai search "JavaScript frameworks" --output-format json
exa-ai search "CSS tips" --output-format pretty

echo ""
echo "5. Context (Code Search)"
exa-ai context "authentication with JWT"
exa-ai context "React hooks" --tokens-num 5000
exa-ai context "async/await" --output-format text

echo ""
echo "6. Get Page Contents"
exa-ai get-contents "https://example.com/article1"
exa-ai get-contents "https://site1.com,https://site2.com" --text
exa-ai get-contents "id1,id2,id3" --highlights --output-format pretty

echo ""
echo "7. Research Tasks"
# Start a research task (returns task ID)
exa-ai research-start --instructions "Find Ruby performance tips"

# Start and wait for completion
exa-ai research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4 \
  --wait

# Check task status
exa-ai research-get "task-id-123"
exa-ai research-get "task-id-123" --events --output-format pretty

# List all tasks
exa-ai research-list
exa-ai research-list --limit 20
exa-ai research-list --cursor "next-page-cursor" --output-format pretty

echo ""
echo "8. Using Custom API Key"
exa-ai search "test" --api-key "your-api-key-here"

echo ""
echo "9. Complex Workflows"
# Search and get contents from top results (requires JSON parsing)
echo "Finding pages about Rust programming and getting their content..."
SEARCH_RESULT=$(exa-ai search "Rust programming best practices" --num-results 3 --output-format json)
echo "$SEARCH_RESULT"

echo ""
echo "=== Examples Complete ==="
echo ""
echo "For more information:"
echo "  - Run: exa-ai --help"
echo "  - Visit: https://docs.exa.ai"
echo "  - Check: README.md"
