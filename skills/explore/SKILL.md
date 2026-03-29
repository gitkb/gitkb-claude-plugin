---
name: explore
description: Explore codebase semantically - find relevant code and documents using natural language search
allowed-tools:
  - mcp__gitkb__kb_semantic
  - mcp__gitkb__kb_search
  - mcp__gitkb__kb_symbols
  - mcp__gitkb__kb_callers
  - mcp__gitkb__kb_callees
---

# /explore <query>

Find relevant code and documents. Prefer GitKB code intelligence first, then use search for broader discovery.
Note: `kb_search` uses FTS, while `kb_semantic` uses the HNSW vector index.

## When to Use

- When exploring unfamiliar code
- When searching by concept rather than exact name
- When trying to find "where does X happen?"
- When investigating functionality across code and docs

## Steps

1. **Try code intelligence first (symbol search):**
   ```
   kb_symbols with search: "<query>"
   ```

2. **For matched symbols, explore structure:**
   ```
   kb_callers with symbol: "<matched-symbol>"
   kb_callees with symbol: "<matched-symbol>"
   ```

3. **Search KB documents for related context:**
   ```
   kb_search with query: "<keywords>"
   ```

4. **Use semantic search for broader discovery:**
   ```
   kb_semantic with query: "<user query>", scope: "all"
   ```

## Output Format

```
## Exploring: "<query>"

### Code Matches

1. **src/services/auth.ts::login** (function) - Score: 0.89
   ```typescript
   export async function login(credentials: Credentials): Promise<Token>
   ```
   Handles user authentication and token generation.

2. **src/middleware/auth.ts::validate** (function) - Score: 0.82
   ```typescript
   export function validate(token: Token): boolean
   ```
   Validates JWT tokens.

### Document Matches

1. **specs/auth-spec** (spec) - Score: 0.85
   "Authentication System Specification"

2. **tasks/my-task** (task) - Score: 0.78
   "Auth Service Refactoring"

### Suggested Next Steps

- `/understand src/services/auth.ts` - Deep dive into auth module
- `/before-refactor login` - Check impact before changes
- `kb_show specs/auth-spec` - Read the auth spec
```

## Example

**Input:** `/explore authentication flow`

**Output:**
```
## Exploring: "authentication flow"

### Code Matches

1. **src/services/auth.ts::login** (function) - Score: 0.91
   ```typescript
   export async function login(credentials: Credentials): Promise<Token>
   ```

2. **src/services/auth.ts::validateToken** (function) - Score: 0.87
   ```typescript
   export function validateToken(token: Token): boolean
   ```

3. **src/middleware/auth.ts::authenticate** (function) - Score: 0.84
   ```typescript
   export async function authenticate(req: Request): Promise<AuthUser>
   ```

### Document Matches

1. **specs/auth-spec** - "Authentication Specification"
2. **context/architecture** - Contains auth section

### Suggested Next Steps

- `/understand src/services/auth.ts` - See full auth module structure
- `kb_show specs/auth-spec` - Read the specification
```

## Scope Options

- `scope: "all"` - Search both code and documents (default)
- `scope: "code"` - Search only code symbols
- `scope: "documents"` - Search only KB documents

## Prerequisites

For code intelligence, the index must be generated:

```bash
git kb code index
```

For semantic search, embeddings must be generated:

```bash
git kb ai embed
```

For document search, documents need embeddings:

```bash
git kb ai embed --scope documents
```
