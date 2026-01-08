# frontmatter: Parse Front Matter from Documents

Extracts and parses YAML or TOML front matter from text documents. Front
matter is structured metadata at the beginning of a document, delimited
by fences.

## Supported Formats

- Standard YAML (`---` delimiters)

- Standard TOML (`+++` delimiters)

- Comment-wrapped formats for R/Python files (`#` and `#'` prefixes)

- PEP 723 Python inline script metadata

## Main Functions

- [`parse_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md):
  Parse front matter from a string

- [`read_front_matter()`](https://posit-dev.github.io/frontmatter/reference/parse_front_matter.md):
  Parse front matter from a file

- [`front_matter_parsers()`](https://posit-dev.github.io/frontmatter/reference/front_matter_parsers.md):
  Create custom parser configuration

## Performance

Uses C++11 for fast, single-pass parsing with minimal memory overhead.
Designed for high throughput processing of many documents.

## Author

**Maintainer**: Garrick Aden-Buie <garrick@adenbuie.com>
([ORCID](https://orcid.org/0000-0002-7111-0077))
