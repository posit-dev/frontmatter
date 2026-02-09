# Changelog

## frontmatter 0.2.0

- New
  [`format_front_matter()`](https://posit-dev.github.io/frontmatter/reference/format_front_matter.md)
  and
  [`write_front_matter()`](https://posit-dev.github.io/frontmatter/reference/format_front_matter.md)
  functions for serializing documents with YAML or TOML front matter.
  These are the inverse of
  [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
  and
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md),
  enabling full roundtrip support. Supports all delimiter formats
  including standard (`---`, `+++`), comment-wrapped (`# ---`,
  `#' ---`), and PEP 723. Note that the roundtrip is not perfect;
  comments and formatting within the front matter content may not be
  preserved.

- [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
  and
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
  now attach `format` and `fence_type` as attributes to the returned
  list, making it easier to preserve the original format when rewriting
  documents.

- Fixed an issue with parsing front matter in comment-prefixed formats
  (e.g., R and Python files) where the body content was not preserved
  correctly. The body is now retained as-is, after stripping any leading
  comment-prefixed empty lines.

## frontmatter 0.1.0

CRAN release: 2026-01-14

- Initial CRAN release.

- Extract and parse YAML or TOML front matter from text documents with
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md)
  or
  [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md).

- Support for multiple front matter formats:

  - Standard [YAML](https://yaml.org/) (`---` delimiters) and
    [TOML](https://toml.io/en/) (`+++` delimiters)
  - Comment-wrapped formats for R and Python files (`#` and `#'`
    prefixes)
  - PEP 723 Python [inline script
    metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)

- Fast C++ parsing with graceful handling of incomplete front matter.

- Flexible parser integration: by default uses
  [`yaml12::parse_yaml()`](https://posit-dev.github.io/r-yaml12/reference/parse_yaml.html)
  and
  [`tomledit::parse_toml()`](https://extendr.github.io/tomledit/reference/read.html)
  or you can provide custom parsers.
