#!/bin/bash
# CLI Usage Examples for Exa Ruby Gem
# Set your API key before running: export EXA_API_KEY="your-key"

echo "=== Exa CLI Usage Examples ==="
echo ""

# Help and version
echo "1. Getting Help"
exa-api --help
exa-api --version
exa-api search --help

echo ""
echo "2. Basic Search"
exa-api search "ruby programming"
exa-api search "machine learning" --num-results 5

echo ""
echo "3. Search with Filtering"
exa-api search "tutorials" \
  --include-domains "github.com,dev.to" \
  --num-results 10

exa-api search "Python" \
  --type neural \
  --exclude-domains "old-blog.com"

echo ""
echo "4. Search with Output Format"
exa-api search "JavaScript frameworks" --output-format json
exa-api search "CSS tips" --output-format pretty

echo ""
echo "5. Context (Code Search)"
exa-api context "authentication with JWT"
exa-api context "React hooks" --tokens-num 5000
exa-api context "async/await" --output-format text

echo ""
echo "6. Get Page Contents"
exa-api get-contents "https://example.com/article1"
exa-api get-contents "https://site1.com,https://site2.com" --text
exa-api get-contents "id1,id2,id3" --highlights --output-format pretty

echo ""
echo "7. Research Tasks"
# Start a research task (returns task ID)
exa-api research-start --instructions "Find Ruby performance tips"

# Start and wait for completion
exa-api research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4 \
  --wait

# Check task status
exa-api research-get "task-id-123"
exa-api research-get "task-id-123" --events --output-format pretty

# List all tasks
exa-api research-list
exa-api research-list --limit 20
exa-api research-list --cursor "next-page-cursor" --output-format pretty

echo ""
echo "8. Using Custom API Key"
exa-api search "test" --api-key "your-api-key-here"

echo ""
echo "9. Complex Workflows"
# Search and get contents from top results (requires JSON parsing)
echo "Finding pages about Rust programming and getting their content..."
SEARCH_RESULT=$(exa-api search "Rust programming best practices" --num-results 3 --output-format json)
echo "$SEARCH_RESULT"

echo ""
echo "=== Examples Complete ==="
echo ""
echo "For more information:"
echo "  - Run: exa-api --help"
echo "  - Visit: https://docs.exa.ai"
echo "  - Check: README.md"
