# Parse YAML or TOML Front Matter

Extract and parse YAML or TOML front matter from a file or a text
string. Front matter is structured metadata at the beginning of a
document, delimited by fences (`---` for YAML, `+++` for TOML).
`parse_front_matter()` processes a character string, while
`read_front_matter()` reads from a file. Both functions return a list
with the parsed front matter and the document body.

## Usage

``` r
parse_front_matter(text, parsers = front_matter_parsers())

read_front_matter(path, parsers = front_matter_parsers())
```

## Arguments

- text:

  A character string or vector containing the document text. If a vector
  with multiple elements, they are joined with newlines (as from
  [`readLines()`](https://rdrr.io/r/base/readLines.html)).

- parsers:

  An optional list of parser functions created by
  [`front_matter_parsers()`](https://posit-dev.github.io/frontmatter/reference/front_matter_parsers.md).
  If `NULL`, default parsers are used.

- path:

  A character string specifying the path to a file. The file is assumed
  to be UTF-8 encoded. A UTF-8 BOM (byte order mark) at the start of the
  file is automatically stripped if present.

## Value

A named list with two elements:

- `data`: The parsed front matter as an R object, or `NULL` if no valid
  front matter was found.

- `body`: The document content after the front matter, with leading
  empty lines removed. If no front matter is found, this is the original
  text.

## Functions

- `parse_front_matter()`: Parse front matter from text

- `read_front_matter()`: Parse front matter from a file.

## Examples

``` r
# Parse YAML front matter
text <- "---
title: My Document
date: 2024-01-01
---
Document content here"

result <- parse_front_matter(text)
result$data$title  # "My Document"
#> [1] "My Document"
result$body        # "Document content here"
#> [1] "Document content here"

# Parse TOML front matter
text <- "+++
title = 'My Document'
date = 2024-01-01
+++
Document content"

result <- parse_front_matter(text)

# Get raw YAML without parsing
result <- parse_front_matter(
  text,
  parsers = front_matter_parsers(yaml = identity)
)

# Or read from a file
tmpfile <- tempfile(fileext = ".md")
writeLines(text, tmpfile)

result <- read_front_matter(tmpfile)
```
