
<!-- README.md is generated from README.Rmd. Please edit that file -->

# frontmatter

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/frontmatter)](https://CRAN.R-project.org/package=frontmatter)
[![R-CMD-check](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml)
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
  - Standard [YAML](https://posit-dev.github.io/r-yaml12/) (`---`
    delimiters)
  - Standard [TOML](https://cran.r-project.org/package=toml) (`+++`
    delimiters)
  - Comment-wrapped formats for R and Python files (`#` and `#'`
    prefixes)
  - [PEP 723](https://peps.python.org/pep-0723/) Python [inline script
    metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)
- **Flexible parser integration** - use default parsers or provide your
  own
- **Graceful handling** of invalid front matter

## Installation

You can install the development version of frontmatter from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
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
```

### Parse from File

``` r
result <- read_front_matter("document.md")
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
#>  $ body: chr "Documentation here"
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
```

### Custom Parsers

``` r
# Get raw YAML without parsing
identity_parser <- front_matter_parsers(yaml = identity)
str(parse_front_matter(text_yaml, parsers = identity_parser))
#> List of 2
#>  $ data: chr "title: My Document\ndate: 2024-01-01\ntags:\n  - tutorial\n  - R\n"
#>  $ body: chr "Document content starts here."

# Use a custom parser that adds metadata
metadata_parser <- front_matter_parsers(
  yaml = function(x) {
    data <- yaml12::parse_yaml(x)
    data$parsed_at <- Sys.time()
    data
  }
)

str(parse_front_matter(text_yaml, parsers = metadata_parser))
#> List of 2
#>  $ data:List of 4
#>   ..$ title    : chr "My Document"
#>   ..$ date     : chr "2024-01-01"
#>   ..$ tags     : chr [1:2] "tutorial" "R"
#>   ..$ parsed_at: POSIXct[1:1], format: "2026-01-08 16:30:14"
#>  $ body: chr "Document content starts here."
```

## Default Parsers

- **YAML**: Uses `yaml12::parse_yaml()` with YAML 1.2 support
- **TOML**: Uses `toml::parse_toml()`

## Error Handling

Invalid front matter returns `NULL` as data and the original content
unchanged:

``` r
text <- "---\nNot valid front matter"
str(parse_front_matter(text))
#> List of 2
#>  $ data: NULL
#>  $ body: chr "---\nNot valid front matter"
```

Parser errors propagate to the caller for proper error handling.

## Performance

The package uses C++11 for optimal performance:

- Single-pass parsing
- Minimal string copying
- Efficient fence detection and validation

Designed for high throughput processing of many documents.
