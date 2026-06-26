# frontmatter (development version)

* `format_front_matter()` and `write_front_matter()` now infer the delimiter
  automatically when `delimiter = NULL` (the new default). If `x` was returned
  by `parse_front_matter()` or `read_front_matter()`, the original fence style
  is preserved; otherwise `write_front_matter()` falls back to the file
  extension of `path`, and finally to `"yaml"` (#8).

* Added support for shebang lines (`#!`) at the start of files. When a file
  begins with a shebang, the parser now recognizes front matter in
  comment-wrapped formats (`# ---`, `#' ---`) and PEP 723 (`# /// script`)
  immediately following the shebang (with zero or one blank lines in between).
  The shebang line is included in the returned `body`. `format_front_matter()`
  and `write_front_matter()` also move a leading shebang line above the front
  matter block when writing (#5).

* Added SQL front matter support with two comment styles: line comments
  (`-- ---`/`-- +++`) and block comments in compact (`/* ---` ... `--- */`) and
  expanded (`/*` + `---` ... `---` + `*/`) forms. Six new delimiter shortcuts
  are available for `write_front_matter()`: `yaml_sql_line`,
  `toml_sql_line`, `yaml_sql_block_compact`, `toml_sql_block_compact`,
  `yaml_sql_block_expanded`, and `toml_sql_block_expanded` (#4).

# frontmatter 0.2.0

* New `format_front_matter()` and `write_front_matter()` functions for serializing documents with YAML or TOML front matter. These are the inverse of `parse_front_matter()` and `read_front_matter()`, enabling full roundtrip support. Supports all delimiter formats including standard (`---`, `+++`), comment-wrapped (`# ---`, `#' ---`), and PEP 723. Note that the roundtrip is not perfect; comments and formatting within the front matter content may not be preserved.

* `parse_front_matter()` and `read_front_matter()` now attach `format` and `fence_type` as attributes to the returned list, making it easier to preserve the original format when rewriting documents.

* Fixed an issue with parsing front matter in comment-prefixed formats (e.g., R and Python files) where the body content was not preserved correctly. The body is now retained as-is, after stripping any leading comment-prefixed empty lines.

# frontmatter 0.1.0

* Initial CRAN release.

* Extract and parse YAML or TOML front matter from text documents with `read_front_matter()` or `parse_front_matter()`.

* Support for multiple front matter formats:
  * Standard [YAML](https://yaml.org/) (`---` delimiters) and [TOML](https://toml.io/en/) (`+++` delimiters)
  * Comment-wrapped formats for R and Python files (`#` and `#'` prefixes)
  * PEP 723 Python [inline script metadata](https://packaging.python.org/en/latest/specifications/inline-script-metadata/#inline-script-metadata)

* Fast C++ parsing with graceful handling of incomplete front matter.

* Flexible parser integration: by default uses `yaml12::parse_yaml()` and `tomledit::parse_toml()` or you can provide custom parsers.
