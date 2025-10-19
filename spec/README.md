# Exa API OpenAPI Specifications

This directory contains the Exa API OpenAPI specifications, split for easy reference during development.

## Files

### Full Specification
- **exa-openapi-spec.yaml** - Complete OpenAPI spec from Exa (1907 lines)
  - Downloaded from: https://raw.githubusercontent.com/exa-labs/openapi-spec/refs/heads/master/exa-openapi-spec.yaml

### Endpoint-Specific Specs
Located in `endpoints/`, these files contain focused views of individual endpoints:

- **search.yaml** - `/search` POST - Main search endpoint
- **findSimilar.yaml** - `/findSimilar` POST - Find similar pages
- **contents.yaml** - `/contents` POST - Get page contents
- **answer.yaml** - `/answer` POST - Get AI-generated answers
- **research_v1.yaml** - `/research/v1` POST - Start research task
- **research_v1_by_id.yaml** - `/research/v1/{researchId}` GET - Get research results

Each endpoint file includes:
- OpenAPI metadata (version, info, servers, security)
- The specific endpoint definition with parameters and examples
- A note pointing to the full components section

### Component Schemas
- **components.yaml** - All reusable schemas, responses, and security definitions
  - Contains shared types like `SearchResult`, `Content`, error schemas, etc.

## Usage

When implementing a new endpoint:

1. Read the specific endpoint file (e.g., `endpoints/search.yaml`) for:
   - Request parameters and their types
   - Request body schema
   - Response structure
   - Code examples in multiple languages

2. Reference `components.yaml` for:
   - Detailed schema definitions referenced by `$ref`
   - Common request/response types
   - Error response formats

3. Use the full `exa-openapi-spec.yaml` if you need to see everything in context

## Updating

To update from the latest Exa spec:

```bash
# Download latest spec
curl -s https://raw.githubusercontent.com/exa-labs/openapi-spec/refs/heads/master/exa-openapi-spec.yaml \
  -o spec/exa-openapi-spec.yaml

# Re-run the extraction script
# (See CLAUDE.md for details)
```
