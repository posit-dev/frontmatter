# Front Matter Parser Specification

## Overview

This specification describes a front matter parser that extracts structured metadata (YAML or TOML) from the beginning of text documents. Front matter is a common pattern in static site generators, documentation systems, and content management tools where metadata is placed at the top of a document, separated from the main content by delimiter fences.

## Use Cases

- **Content Management**: Extracting metadata (title, author, date, tags) from markdown documents
- **Static Site Generators**: Processing blog posts, documentation pages with metadata
- **Documentation Systems**: Handling configuration and metadata in documentation files
- **Content Processing Pipelines**: Separating structured metadata from unstructured content for further processing

## Format Specification

### YAML Front Matter

YAML front matter is delimited by triple-dash fences (`---`).

**Basic Structure:**
```
---
key: value
title: Document Title
date: 2024-01-01
---

Document content starts here
```

### TOML Front Matter

TOML front matter is delimited by triple-plus fences (`+++`).

**Basic Structure:**
```
+++
key = "value"
title = "Document Title"
date = 2024-01-01
+++

Document content starts here
```

## API Behavior

### Function Signature

```
front_matter_read(path, parsers) -> {data: string, body: string}
front_matter_text(text, parsers) -> {data: string, body: string}

front_matter_parsers(yaml, toml) -> {yaml: function, toml: function}
```

### Parameters

1. **path** (string, required): A path to a text file or
2. **text** (string, required): The text content of the document to parse
3. **parsers** (object, optional): Custom parser functions
   - `yaml` (function): Parser for YAML content (receives string between `---` fences)
   - `toml` (function): Parser for TOML content (receives string between `+++` fences)
   - If not provided, default parsers for YAML and TOML are used
   - `front_matter_parsers(yaml, toml)` is a helper to create the parsers object

### Return Value

Returns a named list:
1. **data**: Parsed metadata object, or `NULL` if no valid front matter found
2. **body**: The remaining document content after front matter removal

### Document Content Processing

When valid front matter is found, the returned document content:
- Has all leading empty lines trimmed
- Preserves all other whitespace and formatting
- Begins with the first non-empty line after the closing fence

## Validation Rules

### Opening Fence Requirements

The opening fence must satisfy ALL of the following:

1. **Position**: Must start at the very first character of the document (index 0)
   - No preceding whitespace allowed
   - No preceding newlines allowed
   - No preceding content of any kind

2. **Format**: Must be exactly one of:
   - `---` (for YAML)
   - `+++` (for TOML)

3. **Line Ending**: After the 3-character fence, only whitespace is allowed until newline
   - Trailing spaces and tabs are permitted: `---    \n` ✓
   - Any non-whitespace characters invalidate the fence: `---invalid\n` ✗
   - Must end with a newline character OR be at document end

### Closing Fence Requirements

The closing fence must satisfy ALL of the following:

1. **Format**: Must exactly match the opening fence
   - If opening is `---`, closing must be `---`
   - If opening is `+++`, closing must be `+++`
   - Exactly 3 characters (no more, no less)
   - `----` (4 characters) is NOT a valid closing fence
   - `-----` (5+ characters) is NOT a valid closing fence

2. **Position**: Must be at the start of a line
   - Must be preceded by a newline character
   - No indentation allowed: ` ---\n` ✗

3. **Line Ending**: After the fence, only whitespace until newline
   - Trailing spaces/tabs permitted: `---    \n` ✓
   - Must end with newline OR be at document end

4. **Search Order**: The first valid closing fence is used
   - Parser continues searching until it finds a fence meeting all requirements
   - Invalid candidates (wrong position, indented, wrong length) are skipped

### In R and Python Files

When parsing R and Python files, front matter may be stored within comments. The parser should accept the following forms:

#### Standard comments

``` yaml
# ---
# key: value
# ---

# Document content starts here
```

``` toml
# +++
# key = "value"
# +++

# Document content starts here
```

#### Roxygen-style comments (R only)

```r (yaml)
#' ---
#' key: value
#' ---
#'
#' Document content starts here
```

```r (toml)
#' +++
#' key = "value"
#' +++
#'
#' Document content starts here
```

Remove either leading whitespace lines or lines with only `#'` from the document body.

#### Python script metadata

[Inline script metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata): [PEP 723](https://peps.python.org/pep-0723/) defined a top-level *comment block* that tools can parse as TOML: for the `script` type, the block must start with the exact line `# /// script` (a single `#`, a single space, three slashes, a single space, then `script`) and must end with the exact line `# ///` (a single `#`, a single space, three slashes, and nothing else); every line between those delimiters must be a comment starting with `#`, and if there’s any text after `#` then the next character must be a space (so content lines look like `# key = "value"` or are a bare `#`), with the embedded TOML content obtained by stripping the leading `# ` (or just `#` for empty comment lines).

```python
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests<3",
#     "rich",
# ]
# [tool.my-runner]
# mode = "isolated"
# ///

import requests
from rich.pretty import pprint

pprint(requests.get("https://peps.python.org/api/peps.json").json())
```

The parser should extract the TOML content between the `# /// script` and `# ///` lines, stripping the leading `# ` from each line, and return the remaining document content starting from the line after `# ///`.


### Invalid Front Matter Handling

When front matter is invalid, the parser:
- Returns `NULL` as the data value
- Returns the ENTIRE original content unchanged as the document
- Does NOT throw errors or exceptions

## Edge Cases

### 1. Missing Closing Fence

**Input:**
```
---
title: Document
Rest of content
```

**Behavior**: No closing fence found
**Result**: `{data: null, body: original content}`

### 2. Document Ends After Opening Fence

**Input:**
```
---
```

**Behavior**: No newline after opening fence, no closing fence possible
**Result**: `{data: null, body: original content}`

### 3. Document Ends After Closing Fence

**Input:**
```
---
yaml
---
```

**Behavior**: No content after closing fence
**Result**: `{data: "yaml", body: ""}`

### 4. Trailing Whitespace on Fences

**Input:**
```
---
content
---
Document
```

**Behavior**: Trailing whitespace on fences is allowed
**Result**: Valid front matter parsed

### 5. CRLF Line Endings

**Input:**
```
---\r\n
yaml\r\n
---\r\n
Content\r\n
```

**Behavior**: CRLF (`\r\n`) line endings are treated as valid newlines
**Result**: Front matter parsed correctly, CRLF preserved in document content

### 6. Newline Before Opening Fence

**Input:**
```

---
yaml
---
Content
```

**Behavior**: Opening fence not at document start
**Result**: `{data: null, body: original content}`

### 7. Indented Opening or Closing Fence

**Input:**
```
 ---
yaml
---
```
OR
```
---
yaml
 ---
```

**Behavior**: Indentation invalidates the fence
**Result**: `{data: null, body: original content}`

### 8. Wrong Fence Type

**Input:**
```
>>>
content
>>>
```

**Behavior**: Unrecognized fence delimiter
**Result**: `{data: null, body: original content}`

### 9. Trailing Characters After Opening Fence

**Input:**
```
---invalid
yaml
---
```

**Behavior**: Non-whitespace after opening fence
**Result**: `{data: null, body: original content}`

### 10. Wrong Length Closing Fence

**Input:**
```
---
yaml
----
```

OR

```
---
yaml
------
```

**Behavior**: Closing fence must be exactly 3 characters
**Result**: `{data: null, body: original content}` (continues searching for valid `---`)

### 11. Empty Front Matter

**Input:**
```
---
---
Content
```

**Behavior**: Empty string passed to parser
**Result**: Parser determines result (typically empty object for YAML, error for TOML)

### 12. Multiline Front Matter Content

**Input:**
```
---
title: Document
description: |
  Multi-line
  description
  here
tags:
  - tag1
  - tag2
---
Content
```

**Behavior**: All content between fences passed to parser
**Result**: Parser handles multiline structures according to format (YAML/TOML) rules

### 13. Fence Markers Within Content

**Input:**
```
---
content: "---"
---
Document
```

**Behavior**: First valid closing fence is used
**Result**: Depends on whether the `---` in content is on its own line preceded by newline

### 14. No Document Content

**Input:**
```
---
yaml
---
```

**Behavior**: Valid front matter with empty document
**Result**: `{data: "yaml", body: ""}`

### 15. Leading Whitespace in Document Content

**Input:**
```
---
yaml
---

   Content with leading whitespace
```

**Behavior**: Removes all leading empty lines from document
**Result**: `["yaml", "   Content with leading whitespace"]`

## Custom Parser Behavior

### Raw Front Matter Extraction

Users can provide identity functions to receive unparsed front matter strings:

```r
front_matter_text(
  content,
  parser = front_matter_parsers(yaml = identity, toml = identity)
)
# Result is list(data = "raw front matter string", body = "document content")
```

### Parser Receives Exact Content

The parser function receives:
- The exact string between closing character of opening fence line and opening character of closing fence line
- Includes all newlines within the front matter
- Does NOT include the fence markers themselves
- Does NOT include the newline of the fence lines

**Example:**
```
---
hello
---
```
Parser receives: `"hello\n"`

```
---
hello

world
---
```
Parser receives: `"hello\n\nworld\n"`

### Parser Errors

If a custom parser throws an error, the error propagates to the caller. The specification does not mandate error handling within the parser layer.

## Test Cases

### Basic Functionality Tests

1. **Parse YAML Front Matter**
   - Input: `---\nhello: yaml\n---\nRest of document\n`
   - Expected: `{data: { hello: 'yaml' }, body: 'Rest of document\n'}`

2. **Parse TOML Front Matter**
   - Input: `+++\nhello = "toml"\n+++\nRest of document\n`
   - Expected: `{data: { hello: 'toml' }, body: 'Rest of document\n'}`

3. **No Front Matter**
   - Input: `Rest of document\n`
   - Expected: `{data: null, body: 'Rest of document\n'}`

### Fence Validation Tests

4. **Invalid Opening Fence Character**
   - Input: `>>>\ninvalid\n>>>\nRest of document\n`
   - Expected: `{data: null, body: original content}`

5. **Trailing Characters After Opening Fence**
   - Input: `---invalid\ninvalid\n---\nRest of document\n`
   - Expected: `{data: null, body: original content}`

6. **Indented Opening Fence**
   - Input: ` ---\nyaml\n---\nRest of document\n`
   - Expected: `{data: null, body: original content}`

7. **Opening Fence on Second Line**
   - Input: `\n---\nyaml\n---\nRest of document\n`
   - Expected: `{data: null, body: original content}`

8. **Indented Closing Fence**
   - Input: `---\nyaml\n ---\nRest of document\n`
   - Expected: `{data: null, body: original content}`

9. **4-Character Closing Fence**
   - Input: `---\nyaml\n----\nRest of document\n`
   - Expected: `{data: null, body: original content}`

10. **5-Character Closing Fence**
    - Input: `---\nyaml\n-----\nRest of document\n`
    - Expected: `{data: null, body: original content}`

11. **6-Character Closing Fence**
    - Input: `---\nyaml\n------\nRest of document\n`
    - Expected: `{data: null, body: original content}`

### Whitespace Handling Tests

12. **CRLF Line Endings**
    - Input: `---\r\nyaml\r\n---\r\nRest of document\r\n`
    - Expected: `{data: 'yaml', body: 'Rest of document\r\n'}`

13. **Trailing Space on Opening Fence**
    - Input: `---    \nyaml\n---\nRest of document\n`
    - Expected: `{data: 'yaml', body: 'Rest of document\n'}`

14. **Trailing Space on Closing Fence**
    - Input: `---\nyaml\n---      \nRest of document\n`
    - Expected: `{data: 'yaml', body: 'Rest of document\n'}`

### Document End Tests

15. **Document Ends After Opening Fence**
    - Input: `---`
    - Expected: `{data: null, body: "---"}`

16. **Document Ends After Closing Fence (No Newline)**
    - Input: `---\nyaml\n---`
    - Expected: `{data: 'yaml', body: ''}`

17. **Missing Closing Fence**
    - Input: `---\nRest of document\n`
    - Expected: `{data: null, body: original content}`

### Custom Parser Tests

18. **Custom YAML Parser**
    - Input: `---    \nyaml\n\n---\nRest of document\n`
    - Custom parser receives: `'yaml\n\n'`
    - Parser returns custom value
    - Expected: `{data: custom value, body: 'Rest of document\n'}`

19. **Custom TOML Parser**
    - Input: `+++\ntoml\n\n+++\nRest of document\n`
    - Custom parser receives: `'toml\n\n'`
    - Parser returns custom value
    - Expected: `{data: custom value, body: 'Rest of document\n'}`

### Complex Content Tests

20. **Empty Front Matter Section**
    - Input: `---\n---\nContent`
    - Parser receives: `''`
    - Expected: Parser-dependent (YAML typically returns `null`)

21. **Multiple Potential Closing Fences**
    - Input: `---\nyaml\n----\n---\nContent`
    - Expected: First valid 3-character fence is used
    - Result: `{data: 'yaml\n----', body: 'Content'}`

22. **Front Matter Contains Fence-Like Content**
    - Input: `---\ntitle: My --- Title\n---\nContent`
    - Expected: Continues to first valid closing fence
    - Behavior depends on whether inline `---` matches closing fence rules

## Implementation Considerations

### Performance

- Must scan document character-by-character only once
- Should avoid excessive string copying
- Can short-circuit on first validation failure

### Memory

- Should not load entire document into memory multiple times
- Parser functions receive extracted front matter string only

### Line Ending Compatibility

- Must support LF (`\n`), CRLF (`\r\n`), and potentially CR (`\r`) line endings
- Should preserve original line endings in document content

### Character Encoding

- Must handle UTF-8 encoded content
- Should handle Unicode characters in front matter and document

### Parser Integration

- Should allow any parser function that accepts string and returns any type
- Should not impose requirements on parser error handling
- Default parsers should be easily replaceable

### Error Handling Philosophy

- Invalid front matter is not an error condition
- Returns undefined and original content for graceful degradation
- Allows documents without front matter to pass through unchanged
- Parser errors should propagate (not caught by front matter parser)

## Security Considerations

### Malicious Front Matter

Implementations should consider:
- YAML parsers may execute code in certain configurations (use safe mode)
- Extremely large front matter sections (potential DoS)
- Nested structures with excessive depth
- Regular expression DoS (ReDoS) in fence detection

### Recommended Safeguards

1. Use safe YAML parsing (no code execution)
2. Implement size limits for front matter section
3. Implement line count limits
4. Use non-backtracking regex patterns or simple character comparison
5. Consider timeout mechanisms for parser functions

## Compatibility Notes

### Differences from Other Front Matter Parsers

Some parsers may differ in:
- Allowing longer fence markers (`-----` as valid)
- Allowing alternative fence characters
- Treating indented fences as valid
- Handling of edge cases around document endings

This specification describes strict fence validation to ensure predictable, unambiguous parsing behavior.

### Extension Points

Future enhancements might include:
- Line number reporting for error messages
- Streaming/incremental parsing support

