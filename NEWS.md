# frontmatter 0.1.0

* Initial CRAN release.

* Extract and parse YAML or TOML front matter from text documents with `read_front_matter()` or `parse_front_matter()`.

* Support for multiple front matter formats:
  * Standard [YAML](https://yaml.org/) (`---` delimiters) and [TOML](https://toml.io/en/) (`+++` delimiters)
  * Comment-wrapped formats for R and Python files (`#` and `#'` prefixes)
  * PEP 723 Python [inline script metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)

* Fast C++ parsing with graceful handling of incomplete front matter.

* Flexible parser integration: by default uses `yaml12::parse_yaml()` and `tomledit::parse_toml()` or you can provide custom parsers.
