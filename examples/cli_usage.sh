#!/bin/bash
# CLI Usage Examples for Exa Ruby Gem
# Set your API key before running: export EXA_API_KEY="your-key"

echo "=== Exa CLI Usage Examples ==="
echo ""

# Help and version
echo "1. Getting Help"
exa --help
exa --version
exa search --help

echo ""
echo "2. Basic Search"
exa search "ruby programming"
exa search "machine learning" --num-results 5

echo ""
echo "3. Search with Filtering"
exa search "tutorials" \
  --include-domains "github.com,dev.to" \
  --num-results 10

exa search "Python" \
  --type neural \
  --exclude-domains "old-blog.com"

echo ""
echo "4. Search with Output Format"
exa search "JavaScript frameworks" --output-format json
exa search "CSS tips" --output-format pretty

echo ""
echo "5. Context (Code Search)"
exa context "authentication with JWT"
exa context "React hooks" --tokens-num 5000
exa context "async/await" --output-format text

echo ""
echo "6. Get Page Contents"
exa get-contents "https://example.com/article1"
exa get-contents "https://site1.com,https://site2.com" --text
exa get-contents "id1,id2,id3" --highlights --output-format pretty

echo ""
echo "7. Research Tasks"
# Start a research task (returns task ID)
exa research-start --instructions "Find Ruby performance tips"

# Start and wait for completion
exa research-start \
  --instructions "Analyze AI safety papers" \
  --model gpt-4 \
  --wait

# Check task status
exa research-get "task-id-123"
exa research-get "task-id-123" --events --output-format pretty

# List all tasks
exa research-list
exa research-list --limit 20
exa research-list --cursor "next-page-cursor" --output-format pretty

echo ""
echo "8. Using Custom API Key"
exa search "test" --api-key "your-api-key-here"

echo ""
echo "9. Complex Workflows"
# Search and get contents from top results (requires JSON parsing)
echo "Finding pages about Rust programming and getting their content..."
SEARCH_RESULT=$(exa search "Rust programming best practices" --num-results 3 --output-format json)
echo "$SEARCH_RESULT"

echo ""
echo "=== Examples Complete ==="
echo ""
echo "For more information:"
echo "  - Run: exa --help"
echo "  - Visit: https://docs.exa.ai"
echo "  - Check: README.md"
