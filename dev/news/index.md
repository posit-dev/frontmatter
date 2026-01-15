# Changelog

## frontmatter (development version)

## frontmatter 0.1.0

CRAN release: 2026-01-14

- Initial CRAN release.

- Extract and parse YAML or TOML front matter from text documents with
  [`read_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md)
  or
  [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/dev/reference/parse_front_matter.md).

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
