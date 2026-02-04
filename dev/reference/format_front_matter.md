# Format and Write YAML or TOML Front Matter

Serialize R data as YAML or TOML front matter and combine it with
document content. `format_front_matter()` returns the formatted document
as a string, while `write_front_matter()` writes it to a file or prints
to the console. These functions are the inverse of
[`parse_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
and
[`read_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md).

## Usage

``` r
format_front_matter(
  x,
  delimiter = "yaml",
  format = "auto",
  format_yaml = NULL,
  format_toml = NULL
)

write_front_matter(
  x,
  path = NULL,
  delimiter = "yaml",
  ...,
  format = "auto",
  format_yaml = NULL,
  format_toml = NULL
)
```

## Arguments

- x:

  A list with `data` and `body` elements, typically as returned by
  [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
  or
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md).
  The `data` element contains the metadata to serialize (can be `NULL`
  to write body only), and `body` contains the document content (can be
  `NULL` or empty).

- delimiter:

  A character string specifying the fence style, or a character vector
  for custom delimiters. See **Delimiter Formats** for available
  options.

- format:

  The serialization format: `"auto"` (detect from delimiter), `"yaml"`,
  or `"toml"`. Usually auto-detection works well.

- format_yaml, format_toml:

  Custom formatter functions, or `NULL` to use defaults. Each function
  should accept an R object and return a character string.

- path:

  File path to write to, or `NULL` to print to the console

- ...:

  Additional arguments passed to
  [`writeBin()`](https://rdrr.io/r/base/readBin.html) when writing to a
  file (e.g., `useBytes`).

## Value

- `format_front_matter()`: A character string containing the formatted
  document with front matter.

- `write_front_matter()`: Called for its side effect; returns `NULL`
  invisibly.

## Functions

- `format_front_matter()`: Format front matter as a string

- `write_front_matter()`: Write front matter to a file or console

## Delimiter Formats

The `delimiter` argument controls the fence style used to wrap the front
matter. You can use these built-in shortcuts:

|                  |        |                |          |                                   |
|------------------|--------|----------------|----------|-----------------------------------|
| Shortcut         | Format | Opening        | Closing  | Use Case                          |
| `"yaml"`         | YAML   | `---`          | `---`    | Markdown, R Markdown, Quarto      |
| `"toml"`         | TOML   | `+++`          | `+++`    | Hugo, some static site generators |
| `"yaml_comment"` | YAML   | `# ---`        | `# ---`  | R scripts, Python scripts         |
| `"toml_comment"` | TOML   | `# +++`        | `# +++`  | R scripts, Python scripts         |
| `"yaml_roxy"`    | YAML   | `#' ---`       | `#' ---` | Roxygen2 documentation            |
| `"toml_roxy"`    | TOML   | `#' +++`       | `#' +++` | Roxygen2 documentation            |
| `"toml_pep723"`  | TOML   | `# /// script` | `# ///`  | Python PEP 723 inline metadata    |

For custom delimiters, pass a character vector of length 1, 2, or 3:

- **Length 1**: Used as both opener and closer, with no line prefix

- **Length 2**: `c(opener, prefix)` where opener is also used as closer

- **Length 3**: `c(opener, prefix, closer)` for full control

## Custom Formatters

By default, the package uses
[`yaml12::format_yaml()`](https://posit-dev.github.io/r-yaml12/reference/format_yaml.html)
for YAML and
[`tomledit::to_toml()`](https://extendr.github.io/tomledit/reference/write.html)
for TOML. You can provide custom formatter functions via `format_yaml`
and `format_toml` to override these defaults.

Custom formatters must accept an R object and return a character string
containing the serialized content.

## YAML Specification Version

The default YAML formatter uses YAML 1.2 via
[`yaml12::format_yaml()`](https://posit-dev.github.io/r-yaml12/reference/format_yaml.html).
To use YAML 1.1 formatting instead (via
[`yaml::as.yaml()`](https://yaml.r-lib.org/reference/as.yaml.html)), set
either:

- The R option `frontmatter.serialize_yaml.spec` to `"1.1"`

- The environment variable `FRONTMATTER_SERIALIZE_YAML_SPEC` to `"1.1"`

The option takes precedence over the environment variable. Valid values
are `"1.1"` and `"1.2"` (the default).

## Roundtrip Support

Documents formatted with these functions can be read back with
[`parse_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
or
[`read_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md).
For comment-prefixed formats (like `yaml_comment` or `yaml_roxy`), a
separator line is automatically inserted between the closing fence and
the body when the body starts with the same comment prefix, ensuring
clean roundtrip behavior.

## See also

[`parse_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
and
[`read_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
for the inverse operations.

## Examples

``` r
# Create a document with YAML front matter
doc <- list(
  data = list(title = "My Document", author = "Jane Doe"),
  body = "Document content goes here."
)

# Format as a string
format_front_matter(doc)
#> [1] "---\ntitle: My Document\nauthor: Jane Doe\n---\n\nDocument content goes here."

# Write to a file
tmp <- tempfile(fileext = ".md")
write_front_matter(doc, tmp)
readLines(tmp)
#> Warning: incomplete final line found on '/tmp/Rtmpxp7Sva/file1c16b3cc88d.md'
#> [1] "---"                         "title: My Document"         
#> [3] "author: Jane Doe"            "---"                        
#> [5] ""                            "Document content goes here."

# Print to console (when path is NULL)
write_front_matter(doc)
#> ---
#> title: My Document
#> author: Jane Doe
#> ---
#> 
#> Document content goes here.

# Use TOML format
format_front_matter(doc, delimiter = "toml")
#> [1] "+++\ntitle = \"My Document\"\nauthor = \"Jane Doe\"\n+++\n\nDocument content goes here."

# Use comment-wrapped format for R scripts
r_script <- list(
  data = list(title = "Analysis Script"),
  body = "# Load libraries\nlibrary(dplyr)"
)
format_front_matter(r_script, delimiter = "yaml_comment")
#> [1] "# ---\n# title: Analysis Script\n# ---\n#\n# Load libraries\nlibrary(dplyr)"

# Roundtrip example: read, modify, write
original <- "---
title: Original
---
Content here"

doc <- parse_front_matter(original)
doc$data$title <- "Modified"
format_front_matter(doc)
#> [1] "---\ntitle: Modified\n---\n\nContent here"
```
