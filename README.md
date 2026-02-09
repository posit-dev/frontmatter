
<!-- README.md is generated from README.Rmd. Please edit that file -->

# frontmatter <a href="https://posit-dev.github.io/frontmatter/"><img src="man/figures/logo.png" align="right" height="138" alt="frontmatter website" /></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/frontmatter)](https://CRAN.R-project.org/package=frontmatter)
[![R-CMD-check](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml)
[![R-universe
version](https://posit-dev.r-universe.dev/frontmatter/badges/version)](https://posit-dev.r-universe.dev/frontmatter)
<!-- badges: end -->

## Overview

`frontmatter` extracts and parses structured metadata (YAML or TOML)
from the beginning of text documents. Front matter is a common pattern
in [Quarto documents](https://quarto.org/), [R Markdown
documents](https://rmarkdown.rstudio.com/), static site generators,
documentation systems, content management tools and even
[Python](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)
and [R scripts](https://bookdown.org/yihui/rmarkdown-cookbook/spin.html)
where metadata is placed at the top of a document, separated from the
main content by delimiter fences.

## Features

- **Fast C++ parsing** for optimal performance
- **Multiple formats supported:**
  - Standard [YAML](https://yaml.org/) (`---` delimiters)
  - Standard [TOML](https://toml.io/en/) (`+++` delimiters)
  - Comment-wrapped formats for R and Python files (`#` and `#'`
    prefixes)
  - [PEP 723](https://peps.python.org/pep-0723/) Python [inline script
    metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)
- **Flexible parser integration** - use default parsers or provide your
  own
  - Uses [yaml12](https://posit-dev.github.io/r-yaml12/) for [YAML 1.2
    support](https://posit-dev.github.io/r-yaml12/articles/yaml-2-minute-intro.html)
- **Graceful handling** of invalid front matter

## Installation

You can install frontmatter from CRAN with:

``` r
install.packages("frontmatter")
```

To install the latest development version, you can install from
[posit-dev.r-universe.dev](https://posit-dev.r-universe.dev/):

``` r
# install.packages("pak")

pak::repo_add("https://posit-dev.r-universe.dev")
pak::pak("frontmatter")
```

Or you can install the development version from
[GitHub](https://github.com/posit-dev/frontmatter):

``` r
pak::pak("posit-dev/frontmatter")
```

## Usage

### Basic Usage

``` md
---
title: My Document
date: 2024-01-01
tags:
  - tutorial
  - R
---

Document content starts here.
```

``` r
str(parse_front_matter(text_yaml))
#> List of 2
#>  $ data:List of 3
#>   ..$ title: chr "My Document"
#>   ..$ date : chr "2024-01-01"
#>   ..$ tags : chr [1:2] "tutorial" "R"
#>  $ body: chr "Document content starts here."
#>  - attr(*, "format")= chr "yaml"
#>  - attr(*, "fence_type")= chr "yaml"
#>  - attr(*, "class")= chr "front_matter"
```

### Parse from File

``` r
result <- read_front_matter("document.md")
```

### Write Front Matter

The `format_front_matter()` and `write_front_matter()` functions are the
**inverse** of `parse_front_matter()` and `read_front_matter()`. They
serialize R data structures back to front matter format, enabling you to
programmatically create or modify documents with front matter.

#### Basic Writing

``` r
# Create a document structure
doc <- list(
  data = list(title = "My Document", author = "Jane Doe"),
  body = "Document content goes here."
)

# Format as a string
format_front_matter(doc)
#> [1] "---\ntitle: My Document\nauthor: Jane Doe\n---\n\nDocument content goes here.\n"

# Write to a file
tmp <- tempfile(fileext = ".md")
write_front_matter(doc, tmp)
readLines(tmp)
#> [1] "---"                         "title: My Document"         
#> [3] "author: Jane Doe"            "---"                        
#> [5] ""                            "Document content goes here."

# Print to console (when path is NULL)
write_front_matter(doc, path = NULL)
#> ---
#> title: My Document
#> author: Jane Doe
#> ---
#> 
#> Document content goes here.
```

#### Roundtrip Modification

``` r
# Start with the text_yaml variable from earlier
doc <- parse_front_matter(text_yaml)

# Modify the data
doc$data$title <- "Modified Title"
doc$data$author <- "New Author"

# Format back to string
format_front_matter(doc)
#> [1] "---\ntitle: Modified Title\ndate: 2024-01-01\ntags:\n  - tutorial\n  - R\nauthor: New Author\n---\n\nDocument content starts here.\n"
```

#### Format Options

All delimiter formats supported in parsing are available for writing.
Use these shortcuts with the `delimiter` argument:

- `"yaml"` - Standard YAML (`---`)
- `"toml"` - Standard TOML (`+++`)
- `"yaml_comment"` / `"toml_comment"` - Comment-wrapped for scripts
  (`# ---` / `# +++`)
- `"yaml_roxy"` / `"toml_roxy"` - Roxygen-style (`#' ---` / `#' +++`)
- `"toml_pep723"` - Python PEP 723 (`# /// script`)

See the parsing examples earlier in this README to understand what each
format looks like. Here’s a quick example with TOML:

``` r
# Use TOML format
format_front_matter(doc, delimiter = "toml")
#> [1] "+++\ntitle = \"Modified Title\"\ndate = \"2024-01-01\"\ntags = [\"tutorial\", \"R\"]\nauthor = \"New Author\"\n+++\n\nDocument content starts here.\n"
```

### TOML Front Matter

``` md
+++
title = 'My Document'
count = 42
+++

Content here
```

``` r
str(parse_front_matter(text_toml))
#> List of 2
#>  $ data:List of 2
#>   ..$ title: chr "My Document"
#>   ..$ count: int 42
#>  $ body: chr "Content here"
#>  - attr(*, "format")= chr "toml"
#>  - attr(*, "fence_type")= chr "toml"
#>  - attr(*, "class")= chr "front_matter"
```

### Comment-Wrapped Formats

For R and Python files, front matter can be wrapped in comments:

``` r
# ---
# title: My Analysis
# author: Data Scientist
# ---

library(dplyr)
# Analysis code...
```

``` r
str(parse_front_matter(text_r))
#> List of 2
#>  $ data:List of 2
#>   ..$ title : chr "My Analysis"
#>   ..$ author: chr "Data Scientist"
#>  $ body: chr "library(dplyr)\n# Analysis code..."
#>  - attr(*, "format")= chr "yaml"
#>  - attr(*, "fence_type")= chr "yaml_comment"
#>  - attr(*, "class")= chr "front_matter"
```

Roxygen-style comments are also supported:

``` r
#' ---
#' title: My Function
#' ---
#'
#' Documentation here
```

``` r
str(parse_front_matter(text_roxy))
#> List of 2
#>  $ data:List of 1
#>   ..$ title: chr "My Function"
#>  $ body: chr "#' Documentation here"
#>  - attr(*, "format")= chr "yaml"
#>  - attr(*, "fence_type")= chr "yaml_roxy"
#>  - attr(*, "class")= chr "front_matter"
```

### PEP 723 Python Metadata

``` py
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests<3",
# ]
# ///

import requests
```

``` r
str(parse_front_matter(text_py))
#> List of 2
#>  $ data:List of 2
#>   ..$ requires-python: chr ">=3.11"
#>   ..$ dependencies   :List of 1
#>   .. ..$ : chr "requests<3"
#>  $ body: chr "import requests"
#>  - attr(*, "format")= chr "toml"
#>  - attr(*, "fence_type")= chr "toml_pep723"
#>  - attr(*, "class")= chr "front_matter"
```

### Custom Parsers

``` r
# Get raw YAML without parsing
str(parse_front_matter(text_yaml, parse_yaml = identity))
#> List of 2
#>  $ data: chr "title: My Document\ndate: 2024-01-01\ntags:\n  - tutorial\n  - R\n"
#>  $ body: chr "Document content starts here."
#>  - attr(*, "format")= chr "yaml"
#>  - attr(*, "fence_type")= chr "yaml"
#>  - attr(*, "class")= chr "front_matter"

# Use a custom parser that adds metadata
custom_parser <- function(x) {
  data <- yaml12::parse_yaml(x)
  data$.parsed_with <- "{frontmatter}"
  data
}

str(parse_front_matter(text_yaml, parse_yaml = custom_parser))
#> List of 2
#>  $ data:List of 4
#>   ..$ title       : chr "My Document"
#>   ..$ date        : chr "2024-01-01"
#>   ..$ tags        : chr [1:2] "tutorial" "R"
#>   ..$ .parsed_with: chr "{frontmatter}"
#>  $ body: chr "Document content starts here."
#>  - attr(*, "format")= chr "yaml"
#>  - attr(*, "fence_type")= chr "yaml"
#>  - attr(*, "class")= chr "front_matter"
```

## Default Parsers

- **YAML**: Uses `yaml12::parse_yaml()` with YAML 1.2 support for
  parsing, and `yaml12::format_yaml()` for serialization
- **TOML**: Uses `tomledit::parse_toml()` for parsing, and
  `tomledit::to_toml()` for serialization

### YAML 1.1 Support

To use YAML 1.1 parsing (via the [yaml](https://yaml.r-lib.org) package)
instead of the default YAML 1.2, set either:

- The R option: `options(frontmatter.parse_yaml.spec = "1.1")`
- The environment variable: `FRONTMATTER_PARSE_YAML_SPEC=1.1`

The option takes precedence over the environment variable.

``` md
---
# In YAML 1.1, 'yes' is parsed as TRUE
enabled: yes
---

Content
```

``` r
# Default (YAML 1.2): 'yes' is a string
parse_front_matter(text_yaml11)$data
#> $enabled
#> [1] "yes"

# With YAML 1.1: 'yes' is boolean TRUE
rlang::with_options(
  frontmatter.parse_yaml.spec = "1.1",
  parse_front_matter(text_yaml11)$data
)
#> $enabled
#> [1] TRUE
```

## Error Handling

Incomplete front matter returns `NULL` as data and the original content
unchanged:

``` r
text <- "---\nNot valid front matter"
str(parse_front_matter(text))
#> List of 2
#>  $ data: NULL
#>  $ body: chr "---\nNot valid front matter"
```

Invalid front matter is handled by the parsing function. For example,
invalid YAML will likely result in an error from the YAML parser. Use a
custom parser if you need to handle such cases gracefully.

## Performance

The package uses C++11 for optimal performance:

- Single-pass parsing
- Minimal string copying
- Efficient fence detection and validation

Designed for high throughput processing of many documents.

## Acknowledgments

This package was inspired by the
[simplematter](https://github.com/remcohaszing/simplematter) JavaScript
package.

Thanks also to [Yihui Xie’s](https://yihui.org/) implementation in
[`xfun::yaml_body()`](https://pkg.yihui.org/xfun/manual.html#sec:man-yaml_body).
