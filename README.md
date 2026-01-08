# frontmatter

Parse YAML or TOML front matter from text documents.

## Installation

```r
# Install from source
devtools::install()
```

## Overview

`frontmatter` extracts and parses structured metadata (YAML or TOML) from the beginning of text documents. Front matter is a common pattern in static site generators, documentation systems, and content management tools where metadata is placed at the top of a document, separated from the main content by delimiter fences.

## Features

- **Fast C++ parsing** for optimal performance
- **Multiple formats supported:**
  - Standard YAML (`---` delimiters)
  - Standard TOML (`+++` delimiters)
  - Comment-wrapped formats for R and Python files (`#` and `#'` prefixes)
  - PEP 723 Python inline script metadata
- **Security limits** to prevent DoS attacks (1MB max size, 10K max lines)
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

result <- front_matter_text(text)
result$data$title    # "My Document"
result$data$tags     # c("tutorial", "R")
result$body          # "Document content starts here."
```

### Parse from File

```r
result <- front_matter_read("document.md")
```

### TOML Front Matter

```r
text <- "+++
title = 'My Document'
count = 42
+++

Content here"

result <- front_matter_text(text)
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

result <- front_matter_text(text)
result$data$title    # "My Analysis"
```

Roxygen-style comments are also supported:

```r
text <- "#' ---
#' title: My Function
#' ---
#'
#' Documentation here"

result <- front_matter_text(text)
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

result <- front_matter_text(text)
result$data$`requires-python`  # ">=3.11"
```

### Custom Parsers

```r
# Get raw YAML without parsing
parsers <- front_matter_parsers(yaml = identity)
result <- front_matter_text(text, parsers = parsers)
result$data  # Raw YAML string

# Use custom YAML parser
library(yaml)
parsers <- front_matter_parsers(
  yaml = function(x) yaml::yaml.load(x)
)
result <- front_matter_text(text, parsers = parsers)
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
result <- front_matter_text(text)
result$data  # NULL
result$body  # Original text
```

Parser errors propagate to the caller for proper error handling.

## Security

The package implements security limits to prevent denial-of-service attacks:

- Maximum front matter size: 1 MB
- Maximum line count: 10,000 lines

Documents exceeding these limits are treated as having no front matter.

## Performance

The package uses C++11 for optimal performance:

- Single-pass parsing
- Minimal string copying
- Efficient fence detection and validation

Typical parsing speed: 1000+ documents per second on modern hardware.

## License

MIT License
