#' frontmatter: Parse Front Matter from Documents
#'
#' Extracts and parses YAML or TOML front matter from text documents.
#' Front matter is structured metadata at the beginning of a document,
#' delimited by fences.
#'
#' @section Supported Formats:
#' * Standard YAML (`---` delimiters)
#' * Standard TOML (`+++` delimiters)
#' * Comment-wrapped formats for R/Python files (`#` and `#'` prefixes)
#' * PEP 723 Python inline script metadata
#'
#' @section Main Functions:
#' * [front_matter_text()]: Parse front matter from a string
#' * [front_matter_read()]: Parse front matter from a file
#' * [front_matter_parsers()]: Create custom parser configuration
#'
#' @section Performance:
#' Uses C++11 for fast, single-pass parsing with minimal memory overhead.
#' Designed for high throughput processing of many documents.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import rlang
#' @importFrom cpp11 cpp_source
#' @useDynLib frontmatter, .registration = TRUE
## usethis namespace: end

## mockable bindings: start
## mockable bindings: end
NULL
