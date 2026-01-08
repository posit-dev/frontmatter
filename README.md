
# frontmatter

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/frontmatter)](https://CRAN.R-project.org/package=frontmatter)
[![R-CMD-check](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/posit-dev/frontmatter/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

`frontmatter` extracts and parses structured metadata (YAML or TOML) from the beginning of text documents. Front matter is a common pattern in static site generators, documentation systems, and content management tools where metadata is placed at the top of a document, separated from the main content by delimiter fences.

## Features

- **Fast C++ parsing** for optimal performance
- **Multiple formats supported:**
  - Standard YAML (`---` delimiters)
  - Standard TOML (`+++` delimiters)
  - Comment-wrapped formats for R and Python files (`#` and `#'` prefixes)
  - PEP 723 Python inline script metadata
- **Flexible parser integration** - use default parsers or provide your own
- **Graceful handling** of invalid front matter

## Usage

### Basic Usage

```r
library(frontmatter)

# Parse YAML front matter
text <- "---
title: My Document
date: 2024-01-01
tags:
  - tutorial
  - R
---

Document content starts here."

result <- parse_front_matter(text)
result$data$title    # "My Document"
result$data$tags     # c("tutorial", "R")
result$body          # "Document content starts here."
```

### Parse from File

```r
result <- read_front_matter("document.md")
```

### TOML Front Matter

```r
text <- "+++
title = 'My Document'
count = 42
+++

Content here"

result <- parse_front_matter(text)
result$data$title    # "My Document"
result$data$count    # 42
```

### Comment-Wrapped Formats

For R and Python files, front matter can be wrapped in comments:

```r
# R file with front matter
text <- "# ---
# title: My Analysis
# author: Data Scientist
# ---

library(dplyr)
# Analysis code..."

result <- parse_front_matter(text)
result$data$title    # "My Analysis"
```

Roxygen-style comments are also supported:

```r
text <- "#' ---
#' title: My Function
#' ---
#'
#' Documentation here"

result <- parse_front_matter(text)
```

### PEP 723 Python Metadata

```r
text <- "# /// script
# requires-python = \">=3.11\"
# dependencies = [
#     \"requests<3\",
# ]
# ///

import requests"

result <- parse_front_matter(text)
result$data$`requires-python`  # ">=3.11"
```

### Custom Parsers

```r
# Get raw YAML without parsing
parsers <- front_matter_parsers(yaml = identity)
result <- parse_front_matter(text, parsers = parsers)
result$data  # Raw YAML string

# Use a custom parser that adds metadata
parsers <- front_matter_parsers(
  yaml = function(x) {
    data <- yaml12::parse_yaml(x)
    data$parsed_at <- Sys.time()
    data
  }
)
result <- parse_front_matter(text, parsers = parsers)
```

## Default Parsers

- **YAML**: Uses `yaml12::parse_yaml()` for YAML 1.2 support
- **TOML**: Uses `toml::parse_toml()`

These packages are suggested dependencies. Install them if needed:

```r
install.packages(c("yaml12", "toml"))
```

## Error Handling

Invalid front matter returns `NULL` as data and the original content unchanged:

```r
text <- "Not valid front matter"
result <- parse_front_matter(text)
result$data  # NULL
result$body  # Original text
```

Parser errors propagate to the caller for proper error handling.

## Performance

The package uses C++11 for optimal performance:

- Single-pass parsing
- Minimal string copying
- Efficient fence detection and validation

Designed for high throughput processing of many documents.
