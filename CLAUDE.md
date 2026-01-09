# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Package Overview

`frontmatter` is an R package that extracts and parses YAML/TOML
metadata from the beginning of text documents. It uses a C++11 core (via
cpp11) for fast single-pass parsing, with an R wrapper layer for a
user-friendly API.

## Development Commands

When the r-btw MCP server is available, prefer using its tools: -
`btw_tool_pkg_test` - Run tests (supports `filter` parameter for
specific test files) - `btw_tool_pkg_document` - Rebuild documentation
after changing roxygen comments - `btw_tool_pkg_check` - Run R CMD check

Otherwise, use devtools in R:

``` r
# Run all tests
devtools::test(reporter = "check")
# Run specific test file (matches test-{name}.R)
devtools::test(filter = "pep723", reporter = "check")

devtools::check()     # Run R CMD check
devtools::document()  # Rebuild documentation
devtools::load_all()  # Reload package after C++ changes
```

## Architecture

### Two-Layer Design

1.  **C++ Core** (`src/extract_front_matter.cpp`): Single-pass character
    scanning that detects and extracts front matter. Returns a list with
    `found`, `fence_type`, `content`, and `body`. Handles all format
    detection and validation.

2.  **R Wrapper** (`R/parse_front_matter.R`): User-facing API that calls
    the C++ core, then passes extracted content to the appropriate
    parser (YAML or TOML).

### Format Detection Priority

The C++ code checks formats in this order (most specific first): 1. PEP
723 (`# /// script` … `# ///`) - Python inline script metadata 2.
Comment-wrapped YAML/TOML (`# ---` or `#' ---`) 3. Standard YAML (`---`)
or TOML (`+++`)

### Key Files

- `R/parse_front_matter.R`: Main API -
  [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
  and
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
- `R/default_parsers.R`: Default YAML (yaml12) and TOML (tomledit)
  parsers
- `src/extract_front_matter.cpp`: C++ parsing logic with
  `extract_front_matter_cpp()` as the entry point
- `.claude/SPECIFICATION.md`: Complete parsing specification with edge
  cases

### Parser Flexibility

- Default parsers:
  [`yaml12::parse_yaml()`](https://posit-dev.github.io/r-yaml12/reference/parse_yaml.html)
  (YAML 1.2) and
  [`tomledit::parse_toml()`](https://extendr.github.io/tomledit/reference/read.html)
- Users can override via `parse_yaml` and `parse_toml` arguments
- YAML 1.1 available via option `frontmatter.parse_yaml.spec = "1.1"` or
  envvar `FRONTMATTER_PARSE_YAML_SPEC=1.1`

## Testing

Tests are organized by feature in `tests/testthat/`: -
`test-fence-validation.R`: Edge cases for fence detection (exact 3
chars, indentation, etc.) - `test-comment-formats.R`: Comment-wrapped
formats (`#` and `#'` prefixes) - `test-pep723.R`: Python inline script
metadata - `test-whitespace.R`: CRLF/LF handling, trailing whitespace -
`test-encoding.R`: UTF-8, BOM handling - `test-custom-parsers.R`: Custom
parser functions - `fixtures/`: Test fixture files

## Specification Reference

The complete parsing specification is in `.claude/SPECIFICATION.md`. Key
rules: - Opening fence must be at document position 0 - Closing fence
must be exactly 3 characters (not 4+) - Invalid front matter returns
`NULL` data with original content as body (no errors) - For
comment-wrapped formats, closing fence must use same prefix as opening
